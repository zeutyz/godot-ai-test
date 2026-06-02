class_name TerrainChunk
extends MeshInstance3D

var chunk_coord: Vector2i = Vector2i.ZERO
var chunk_size: float = 64.0
var resolution: int = 64
var world_profile: RefCounted
var terrain_material: Material
var _average_normal_y: float = 1.0

# Estruturas de dados compartilhadas de forma segura para a vegetação
var faces_positions: PackedVector3Array = PackedVector3Array()
var faces_normals: PackedVector3Array = PackedVector3Array()

var _thread_generated_mesh_data: Array = []
var _is_data_ready: bool = false


func setup(
		p_chunk_coord: Vector2i,
		p_chunk_size: float,
		p_resolution: int,
		p_world_profile: RefCounted,
		p_material: Material) -> void:
	chunk_coord = p_chunk_coord
	chunk_size = p_chunk_size
	resolution = p_resolution
	world_profile = p_world_profile
	terrain_material = p_material
	position = Vector3(float(chunk_coord.x) * chunk_size, 0.0, float(chunk_coord.y) * chunk_size)
	material_override = terrain_material


# Executado em Thread Secundária
func generate_data_offline() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertex_count: int = resolution + 1
	var step: float = chunk_size / float(resolution)

	var world_origin_x: float = float(chunk_coord.x) * chunk_size
	var world_origin_z: float = float(chunk_coord.y) * chunk_size
	var uv_scale: float = 1.0 / chunk_size

	# 1. Armazenar vértices temporários em uma grade local para mapear os triângulos facilmente
	var vertices_grid: Array = []
	for z_index: int in range(vertex_count):
		var row: PackedVector3Array = PackedVector3Array()
		for x_index: int in range(vertex_count):
			var local_x: float = float(x_index) * step
			var local_z: float = float(z_index) * step
			var world_x: float = world_origin_x + local_x
			var world_z: float = world_origin_z + local_z
			var world_sample: Dictionary = world_profile.sample_world(world_x, world_z)
			var height: float = float(world_sample["height"])
			row.append(Vector3(local_x, height, local_z))
		vertices_grid.append(row)

	# 2. Construir superfícies e popular as arrays de faces para amostragem da vegetação
	for z_index: int in range(resolution):
		for x_index: int in range(resolution):
			var p0: Vector3 = vertices_grid[z_index][x_index]
			var p1: Vector3 = vertices_grid[z_index][x_index + 1]
			var p2: Vector3 = vertices_grid[z_index + 1][x_index]
			var p3: Vector3 = vertices_grid[z_index + 1][x_index + 1]

			# Mapeamento Global UV para eliminar emendas visuais
			var uv0: Vector2 = Vector2((world_origin_x + p0.x) * uv_scale, (world_origin_z + p0.z) * uv_scale)
			var uv1: Vector2 = Vector2((world_origin_x + p1.x) * uv_scale, (world_origin_z + p1.z) * uv_scale)
			var uv2: Vector2 = Vector2((world_origin_x + p2.x) * uv_scale, (world_origin_z + p2.z) * uv_scale)
			var uv3: Vector2 = Vector2((world_origin_x + p3.x) * uv_scale, (world_origin_z + p3.z) * uv_scale)

			# Triângulo 1
			surface_tool.set_uv(uv0)
			surface_tool.add_vertex(p0)
			surface_tool.set_uv(uv1)
			surface_tool.add_vertex(p1)
			surface_tool.set_uv(uv2)
			surface_tool.add_vertex(p2)

			# Triângulo 2
			surface_tool.set_uv(uv1)
			surface_tool.add_vertex(p1)
			surface_tool.set_uv(uv3)
			surface_tool.add_vertex(p3)
			surface_tool.set_uv(uv2)
			surface_tool.add_vertex(p2)

			# Salvar as faces no espaço local para uso no espalhamento da vegetação
			faces_positions.append(p0); faces_positions.append(p1); faces_positions.append(p2)
			faces_positions.append(p1); faces_positions.append(p3); faces_positions.append(p2)

	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	
	_thread_generated_mesh_data = surface_tool.commit_to_arrays()
	_average_normal_y = _measure_average_normal_y_from_arrays(_thread_generated_mesh_data)
	
	# Extrair normais das faces geradas
	var mesh_normals: PackedVector3Array = _thread_generated_mesh_data[Mesh.ARRAY_NORMAL]
	for i: int in range(0, mesh_normals.size(), 3):
		if i + 2 < mesh_normals.size():
			faces_normals.append(mesh_normals[i])
			faces_normals.append(mesh_normals[i+1])
			faces_normals.append(mesh_normals[i+2])

	_is_data_ready = true


func finalize_mesh_on_main_thread() -> void:
	if not _is_data_ready or _thread_generated_mesh_data.is_empty():
		return
		
	var built_mesh: ArrayMesh = ArrayMesh.new()
	built_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _thread_generated_mesh_data)
	mesh = built_mesh


func get_average_normal_y() -> float:
	return _average_normal_y


func _measure_average_normal_y_from_arrays(arrays: Array) -> float:
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if normals.is_empty():
		return 0.0

	var sum_y: float = 0.0
	for normal: Vector3 in normals:
		sum_y += normal.y
	return sum_y / float(normals.size())
