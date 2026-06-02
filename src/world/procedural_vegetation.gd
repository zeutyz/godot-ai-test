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

var _tree_material: ShaderMaterial
var _trunk_material: ShaderMaterial
var _grass_material: ShaderMaterial
var _reed_material: ShaderMaterial
var _bush_material: ShaderMaterial
var _rock_material: ShaderMaterial
var _metrics: Dictionary = {
	"grass": 0,
	"trees": 0,
	"crowns": 0,
	"reeds": 0,
	"bushes": 0,
	"rocks": 0,
	"max_tree_height": 0.0,
}


func setup(p_chunk_coord: Vector2i, p_chunk_size: float, p_world_profile: RefCounted, p_seed: int, p_lod_level: int) -> void:
	chunk_coord = p_chunk_coord
	chunk_size = p_chunk_size
	world_profile = p_world_profile
	seed = p_seed
	lod_level = p_lod_level
	position = Vector3.ZERO
	_create_materials()
	_build_grass()
	_build_reeds()
	_build_bushes()
	_build_rocks()
	_build_trees()
	_build_distant_canopy_hints()


func _create_materials() -> void:
	_tree_material = _make_foliage_material(Color(0.20, 0.45, 0.21), 0.18, 0.42, 1.0)
	_grass_material = _make_foliage_material(Color(0.35, 0.58, 0.19), 0.30, 0.82, 0.0)
	_reed_material = _make_foliage_material(Color(0.46, 0.55, 0.24), 0.55, 0.82, 0.0)
	_bush_material = _make_foliage_material(Color(0.31, 0.53, 0.24), 0.24, 0.48, 0.75)
	_trunk_material = _make_solid_material(Color(0.40, 0.28, 0.17))
	_rock_material = _make_solid_material(Color(0.43, 0.42, 0.38))


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


func _build_grass() -> void:
	var transforms: Array[Transform3D] = []
	for layer_index: int in range(2):
		var cell_count: int = _scaled_cell_count(50 - layer_index * 10)
		var cell_size: float = chunk_size / float(cell_count)
		var layer_salt: int = 2000 + layer_index * 311

		for z_index: int in range(cell_count):
			for x_index: int in range(cell_count):
				var local_x: float = (float(x_index) + _hash_unit(x_index, z_index, layer_salt + 3)) * cell_size
				var local_z: float = (float(z_index) + _hash_unit(x_index, z_index, layer_salt + 7)) * cell_size
				_append_grass_transform(transforms, x_index, z_index, layer_salt, local_x, local_z)

	_metrics["grass"] = transforms.size()
	_create_multimesh("GrassTufts", _make_grass_mesh(), _grass_material, transforms)


func _append_grass_transform(transforms: Array[Transform3D], x_index: int, z_index: int, salt: int, local_x: float, local_z: float) -> void:
	var world_x: float = _chunk_world_x() + local_x
	var world_z: float = _chunk_world_z() + local_z
	var world_sample: Dictionary = world_profile.sample_world(world_x, world_z)
	var height: float = float(world_sample["height"])
	var biome: int = int(world_sample["biome"])
	var slope: float = float(world_sample["slope"])
	var fertility: float = float(world_sample["fertility"])
	var moisture: float = float(world_sample["moisture"])

	if slope > 0.56:
		return
	if biome != WORLD_PROFILE_SCRIPT.Biome.MEADOW and biome != WORLD_PROFILE_SCRIPT.Biome.FOREST and biome != WORLD_PROFILE_SCRIPT.Biome.HIGHLAND:
		return
	if _hash_unit(x_index, z_index, salt + 19) > 0.76 + fertility * 0.24:
		return

	var scale_y: float = 0.18 + moisture * 0.34 + _hash_unit(x_index, z_index, salt + 11) * 0.30
	var scale_xz: float = 0.50 + _hash_unit(x_index, z_index, salt + 13) * 0.30
	var basis: Basis = Basis(Vector3.UP, _hash_unit(x_index, z_index, salt + 17) * TAU)
	basis = basis.scaled(Vector3(scale_xz, scale_y, scale_xz))
	transforms.append(Transform3D(basis, Vector3(local_x, height + 0.04, local_z)))


func _build_reeds() -> void:
	var transforms: Array[Transform3D] = []
	var cell_count: int = _scaled_cell_count(18)
	var cell_size: float = chunk_size / float(cell_count)

	for z_index: int in range(cell_count):
		for x_index: int in range(cell_count):
			var local_x: float = (float(x_index) + _hash_unit(x_index, z_index, 23)) * cell_size
			var local_z: float = (float(z_index) + _hash_unit(x_index, z_index, 29)) * cell_size
			var world_x: float = _chunk_world_x() + local_x
			var world_z: float = _chunk_world_z() + local_z
			var world_sample: Dictionary = world_profile.sample_world(world_x, world_z)
			var height: float = float(world_sample["height"])
			var biome: int = int(world_sample["biome"])
			if biome != WORLD_PROFILE_SCRIPT.Biome.WETLAND and biome != WORLD_PROFILE_SCRIPT.Biome.BEACH:
				continue

			var scale_y: float = 1.2 + _hash_unit(x_index, z_index, 31) * 1.5
			var basis: Basis = Basis(Vector3.UP, _hash_unit(x_index, z_index, 37) * TAU)
			basis = basis.scaled(Vector3(0.55, scale_y, 0.55))
			transforms.append(Transform3D(basis, Vector3(local_x, height + 0.1, local_z)))

	_metrics["reeds"] = transforms.size()
	_create_multimesh("Reeds", _make_grass_mesh(), _reed_material, transforms)


func _build_bushes() -> void:
	var transforms: Array[Transform3D] = []
	var cell_count: int = _scaled_cell_count(14)
	var cell_size: float = chunk_size / float(cell_count)

	for z_index: int in range(cell_count):
		for x_index: int in range(cell_count):
			var local_x: float = (float(x_index) + _hash_unit(x_index, z_index, 61)) * cell_size
			var local_z: float = (float(z_index) + _hash_unit(x_index, z_index, 67)) * cell_size
			var world_x: float = _chunk_world_x() + local_x
			var world_z: float = _chunk_world_z() + local_z
			var world_sample: Dictionary = world_profile.sample_world(world_x, world_z)
			var height: float = float(world_sample["height"])
			var biome: int = int(world_sample["biome"])
			var slope: float = float(world_sample["slope"])
			var fertility: float = float(world_sample["fertility"])

			if slope > 0.42:
				continue
			if biome != WORLD_PROFILE_SCRIPT.Biome.MEADOW and biome != WORLD_PROFILE_SCRIPT.Biome.FOREST and biome != WORLD_PROFILE_SCRIPT.Biome.WETLAND:
				continue
			if _hash_unit(x_index, z_index, 71) > fertility * 0.55:
				continue

			var bush_scale: float = 0.65 + _hash_unit(x_index, z_index, 73) * 0.7
			var basis: Basis = Basis(Vector3.UP, _hash_unit(x_index, z_index, 79) * TAU)
			basis = basis.scaled(Vector3(1.35 * bush_scale, 0.75 * bush_scale, 1.35 * bush_scale))
			transforms.append(Transform3D(basis, Vector3(local_x, height + 0.55 * bush_scale, local_z)))

	_metrics["bushes"] = transforms.size()
	_create_multimesh("Bushes", _make_bush_mesh(), _bush_material, transforms)


func _build_rocks() -> void:
	var transforms: Array[Transform3D] = []
	var cell_count: int = _scaled_cell_count(9)
	var cell_size: float = chunk_size / float(cell_count)

	for z_index: int in range(cell_count):
		for x_index: int in range(cell_count):
			var local_x: float = (float(x_index) + _hash_unit(x_index, z_index, 83)) * cell_size
			var local_z: float = (float(z_index) + _hash_unit(x_index, z_index, 89)) * cell_size
			var world_x: float = _chunk_world_x() + local_x
			var world_z: float = _chunk_world_z() + local_z
			var world_sample: Dictionary = world_profile.sample_world(world_x, world_z)
			var height: float = float(world_sample["height"])
			var biome: int = int(world_sample["biome"])
			var slope: float = float(world_sample["slope"])

			var rock_chance: float = 0.06 + slope * 0.38
			if biome == WORLD_PROFILE_SCRIPT.Biome.ROCK or biome == WORLD_PROFILE_SCRIPT.Biome.HIGHLAND:
				rock_chance += 0.34
			elif biome == WORLD_PROFILE_SCRIPT.Biome.BEACH:
				rock_chance += 0.08
			elif biome == WORLD_PROFILE_SCRIPT.Biome.WATER or biome == WORLD_PROFILE_SCRIPT.Biome.SNOW:
				rock_chance = 0.0

			if _hash_unit(x_index, z_index, 97) > rock_chance:
				continue

			var rock_scale: float = 0.45 + _hash_unit(x_index, z_index, 101) * 1.6
			var basis: Basis = Basis(Vector3.UP, _hash_unit(x_index, z_index, 103) * TAU)
			basis = basis.scaled(Vector3(
					1.25 * rock_scale,
					0.55 * rock_scale + slope * 0.65,
					0.85 * rock_scale))
			transforms.append(Transform3D(basis, Vector3(local_x, height + 0.25 * rock_scale, local_z)))

	_metrics["rocks"] = transforms.size()
	_create_multimesh("Rocks", _make_rock_mesh(), _rock_material, transforms)


func _build_trees() -> void:
	var leaf_transforms: Array[Transform3D] = []
	var trunk_transforms: Array[Transform3D] = []
	var max_tree_height: float = 0.0
	var cell_count: int = _scaled_cell_count(11)
	var cell_size: float = chunk_size / float(cell_count)

	for z_index: int in range(cell_count):
		for x_index: int in range(cell_count):
			if _hash_unit(x_index, z_index, 41) < 0.18:
				continue

			var local_x: float = (float(x_index) + _hash_unit(x_index, z_index, 43)) * cell_size
			var local_z: float = (float(z_index) + _hash_unit(x_index, z_index, 47)) * cell_size
			var world_x: float = _chunk_world_x() + local_x
			var world_z: float = _chunk_world_z() + local_z
			var world_sample: Dictionary = world_profile.sample_world(world_x, world_z)
			var height: float = float(world_sample["height"])
			var biome: int = int(world_sample["biome"])
			var slope: float = float(world_sample["slope"])
			var fertility: float = float(world_sample["fertility"])

			if biome != WORLD_PROFILE_SCRIPT.Biome.FOREST or slope > 0.44:
				continue
			if _hash_unit(x_index, z_index, 107) > 0.62 + fertility * 0.35:
				continue
			if not _wins_tree_priority(x_index, z_index):
				continue

			var tree_scale: float = 0.85 + _hash_unit(x_index, z_index, 53) * 0.85
			var trunk_height: float = 10.5 + tree_scale * 7.5 + fertility * 4.5
			var crown_height: float = 7.0 + tree_scale * 4.2
			var crown_width: float = 5.8 + tree_scale * 3.8
			max_tree_height = maxf(max_tree_height, trunk_height + crown_height)
			var yaw: float = _hash_unit(x_index, z_index, 59) * TAU
			var trunk_basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3(0.9 * tree_scale, trunk_height, 0.9 * tree_scale))
			trunk_transforms.append(Transform3D(trunk_basis, Vector3(local_x, height + trunk_height * 0.5, local_z)))

			for crown_index: int in range(3):
				var offset_angle: float = yaw + float(crown_index) * TAU / 3.0
				var offset_radius: float = 0.9 + _hash_unit(x_index, z_index, 121 + crown_index) * 1.6
				var crown_x: float = local_x + cos(offset_angle) * offset_radius
				var crown_z: float = local_z + sin(offset_angle) * offset_radius
				var crown_scale: float = 0.78 + _hash_unit(x_index, z_index, 131 + crown_index) * 0.34
				var leaf_basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3(
						crown_width * crown_scale,
						crown_height * crown_scale,
						crown_width * crown_scale))
				var crown_y: float = height + trunk_height + crown_height * 0.25 + float(crown_index) * 0.85
				leaf_transforms.append(Transform3D(leaf_basis, Vector3(crown_x, crown_y, crown_z)))

	_metrics["trees"] = trunk_transforms.size()
	_metrics["crowns"] = leaf_transforms.size()
	_metrics["max_tree_height"] = max_tree_height
	_create_multimesh("TreeTrunks", _make_trunk_mesh(), _trunk_material, trunk_transforms)
	_create_multimesh("TreeCrowns", _make_crown_mesh(), _tree_material, leaf_transforms)


func _build_distant_canopy_hints() -> void:
	if lod_level < 2:
		return

	var transforms: Array[Transform3D] = []
	var cell_count: int = 8
	var cell_size: float = chunk_size / float(cell_count)
	for z_index: int in range(cell_count):
		for x_index: int in range(cell_count):
			var local_x: float = (float(x_index) + _hash_unit(x_index, z_index, 401)) * cell_size
			var local_z: float = (float(z_index) + _hash_unit(x_index, z_index, 409)) * cell_size
			var world_x: float = _chunk_world_x() + local_x
			var world_z: float = _chunk_world_z() + local_z
			var sample: Dictionary = world_profile.sample_world(world_x, world_z)
			var biome: int = int(sample["biome"])
			var slope: float = float(sample["slope"])
			if biome != WORLD_PROFILE_SCRIPT.Biome.FOREST or slope > 0.52:
				continue
			if _hash_unit(x_index, z_index, 419) > 0.62:
				continue

			var height: float = float(sample["height"])
			var scale: float = 5.0 + _hash_unit(x_index, z_index, 421) * 4.5
			var basis: Basis = Basis(Vector3.UP, _hash_unit(x_index, z_index, 431) * TAU)
			basis = basis.scaled(Vector3(scale * 1.4, scale * 0.95, scale * 1.4))
			transforms.append(Transform3D(basis, Vector3(local_x, height + scale * 2.0, local_z)))

	_create_multimesh("DistantCanopyHints", _make_crown_mesh(), _tree_material, transforms)


func get_metrics() -> Dictionary:
	return _metrics.duplicate()


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
		surface_tool.add_vertex(a)
		surface_tool.add_vertex(b)
		surface_tool.add_vertex(c)
		surface_tool.add_vertex(a)
		surface_tool.add_vertex(c)
		surface_tool.add_vertex(d)
		surface_tool.add_vertex(c)
		surface_tool.add_vertex(b)
		surface_tool.add_vertex(a)
		surface_tool.add_vertex(d)
		surface_tool.add_vertex(c)
		surface_tool.add_vertex(a)
	surface_tool.generate_normals()
	return surface_tool.commit()


func _make_trunk_mesh() -> ArrayMesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = 8
	var rings: int = 4
	for ring_index: int in range(rings + 1):
		var t: float = float(ring_index) / float(rings)
		var radius: float = lerpf(0.34, 0.18, t)
		var y: float = t
		for segment_index: int in range(segments):
			var angle: float = float(segment_index) * TAU / float(segments)
			var wobble: float = sin(t * PI * 2.0 + angle * 1.7) * 0.035
			surface_tool.add_vertex(Vector3(cos(angle) * (radius + wobble), y, sin(angle) * (radius - wobble)))

	for ring_index: int in range(rings):
		for segment_index: int in range(segments):
			var next_segment: int = (segment_index + 1) % segments
			var a: int = ring_index * segments + segment_index
			var b: int = ring_index * segments + next_segment
			var c: int = (ring_index + 1) * segments + segment_index
			var d: int = (ring_index + 1) * segments + next_segment
			surface_tool.add_index(a)
			surface_tool.add_index(c)
			surface_tool.add_index(b)
			surface_tool.add_index(b)
			surface_tool.add_index(c)
			surface_tool.add_index(d)

	surface_tool.generate_normals()
	return surface_tool.commit()


func _make_crown_mesh() -> ArrayMesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for plane_index: int in range(3):
		var yaw: float = float(plane_index) * TAU / 3.0
		var right: Vector3 = Vector3(cos(yaw), 0.0, sin(yaw))
		var up: Vector3 = Vector3(0.0, 1.0, 0.0)
		_add_leaf_quad(surface_tool, -right - up * 0.55, right - up * 0.48, right * 0.82 + up * 0.66, -right * 0.82 + up * 0.74)
		_add_leaf_quad(surface_tool, -right * 0.72 - up * 0.10, right * 0.72 - up * 0.06, right * 0.48 + up * 1.02, -right * 0.50 + up * 0.96)
	surface_tool.generate_normals()
	return surface_tool.commit()


func _add_leaf_quad(surface_tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	surface_tool.add_vertex(a)
	surface_tool.add_vertex(b)
	surface_tool.add_vertex(c)
	surface_tool.add_vertex(a)
	surface_tool.add_vertex(c)
	surface_tool.add_vertex(d)
	surface_tool.add_vertex(c)
	surface_tool.add_vertex(b)
	surface_tool.add_vertex(a)
	surface_tool.add_vertex(d)
	surface_tool.add_vertex(c)
	surface_tool.add_vertex(a)


func _make_bush_mesh() -> SphereMesh:
	var bush: SphereMesh = SphereMesh.new()
	bush.radius = 1.0
	bush.height = 1.1
	bush.radial_segments = 8
	bush.rings = 5
	return bush


func _make_rock_mesh() -> SphereMesh:
	var rock: SphereMesh = SphereMesh.new()
	rock.radius = 1.0
	rock.height = 1.0
	rock.radial_segments = 7
	rock.rings = 4
	return rock


func _chunk_world_x() -> float:
	return float(chunk_coord.x) * chunk_size


func _chunk_world_z() -> float:
	return float(chunk_coord.y) * chunk_size


func _hash_unit(x_index: int, z_index: int, salt: int) -> float:
	var hash: int = int(chunk_coord.x * 73856093) ^ int(chunk_coord.y * 19349663) ^ int(x_index * 83492791) ^ int(z_index * 2654435761) ^ int(seed + salt * 374761393)
	hash = (hash ^ (hash >> 13)) * 1274126177
	hash = hash ^ (hash >> 16)
	return float(hash & 0xffff) / 65535.0


func _wins_tree_priority(x_index: int, z_index: int) -> bool:
	var own_priority: float = _hash_unit(x_index, z_index, 301)
	for z_offset: int in range(-1, 2):
		for x_offset: int in range(-1, 2):
			if x_offset == 0 and z_offset == 0:
				continue
			var neighbor_x: int = x_index + x_offset
			var neighbor_z: int = z_index + z_offset
			var neighbor_priority: float = _hash_unit(neighbor_x, neighbor_z, 301)
			var neighbor_candidate: float = _hash_unit(neighbor_x, neighbor_z, 107)
			if neighbor_candidate <= 0.88 and neighbor_priority > own_priority:
				return false
	return true


func _scaled_cell_count(base_count: int) -> int:
	if lod_level <= 0:
		return base_count
	if lod_level == 1:
		return maxi(4, int(round(float(base_count) * 0.45)))
	return maxi(2, int(round(float(base_count) * 0.24)))
