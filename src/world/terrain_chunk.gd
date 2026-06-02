class_name TerrainChunk
extends MeshInstance3D

var chunk_coord: Vector2i = Vector2i.ZERO
var chunk_size: float = 64.0
var resolution: int = 64
var world_profile: RefCounted
var terrain_material: Material
var _average_normal_y: float = 1.0


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
	mesh = _build_mesh()
	material_override = terrain_material


func _build_mesh() -> ArrayMesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertex_count: int = resolution + 1
	var step: float = chunk_size / float(resolution)

	for z_index: int in range(vertex_count):
		for x_index: int in range(vertex_count):
			var local_x: float = float(x_index) * step
			var local_z: float = float(z_index) * step
			var world_x: float = position.x + local_x
			var world_z: float = position.z + local_z
			var world_sample: Dictionary = world_profile.sample_world(world_x, world_z)
			var height: float = float(world_sample["height"])
			surface_tool.set_uv(Vector2(float(x_index) / float(resolution), float(z_index) / float(resolution)))
			surface_tool.set_color(world_profile.blended_color_for_world(world_x, world_z))
			surface_tool.add_vertex(Vector3(local_x, height, local_z))

	for z_index: int in range(resolution):
		for x_index: int in range(resolution):
			var top_left: int = z_index * vertex_count + x_index
			var top_right: int = top_left + 1
			var bottom_left: int = top_left + vertex_count
			var bottom_right: int = bottom_left + 1
			surface_tool.add_index(top_left)
			surface_tool.add_index(top_right)
			surface_tool.add_index(bottom_left)
			surface_tool.add_index(top_right)
			surface_tool.add_index(bottom_right)
			surface_tool.add_index(bottom_left)

	surface_tool.generate_normals()
	var built_mesh: ArrayMesh = surface_tool.commit()
	_average_normal_y = _measure_average_normal_y(built_mesh)
	return built_mesh


func get_average_normal_y() -> float:
	return _average_normal_y


func _measure_average_normal_y(built_mesh: ArrayMesh) -> float:
	if built_mesh.get_surface_count() <= 0:
		return 1.0

	var arrays: Array = built_mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if normals.is_empty():
		return 0.0

	var sum_y: float = 0.0
	for normal: Vector3 in normals:
		sum_y += normal.y
	return sum_y / float(normals.size())
