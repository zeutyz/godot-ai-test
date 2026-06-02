class_name ProceduralWaterFeatures
extends Node3D

const WORLD_PROFILE_SCRIPT = preload("res://src/world/world_profile.gd")

var chunk_coord: Vector2i = Vector2i.ZERO
var chunk_size: float = 64.0
var world_profile: RefCounted
var seed: int = 0
var lod_level: int = 0
var _water_material: StandardMaterial3D


func setup(p_chunk_coord: Vector2i, p_chunk_size: float, p_world_profile: RefCounted, p_seed: int, p_lod_level: int) -> void:
	chunk_coord = p_chunk_coord
	chunk_size = p_chunk_size
	world_profile = p_world_profile
	seed = p_seed
	lod_level = p_lod_level
	_create_material()
	_build_water_marks()


func _create_material() -> void:
	_water_material = StandardMaterial3D.new()
	_water_material.albedo_color = Color(0.30, 0.56, 0.66, 0.68)
	_water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_water_material.roughness = 0.42
	_water_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX


func _build_water_marks() -> void:
	var transforms: Array[Transform3D] = []
	var cell_count: int = 8 if lod_level == 0 else 5
	var cell_size: float = chunk_size / float(cell_count)

	for z_index: int in range(cell_count):
		for x_index: int in range(cell_count):
			var local_x: float = (float(x_index) + _hash_unit(x_index, z_index, 5)) * cell_size
			var local_z: float = (float(z_index) + _hash_unit(x_index, z_index, 9)) * cell_size
			var world_x: float = _chunk_world_x() + local_x
			var world_z: float = _chunk_world_z() + local_z
			var world_sample: Dictionary = world_profile.sample_world(world_x, world_z)
			var height: float = float(world_sample["height"])
			var biome: int = int(world_sample["biome"])
			var flow: float = float(world_sample["flow"])
			var slope: float = float(world_sample["slope"])

			if biome == WORLD_PROFILE_SCRIPT.Biome.WATER or biome == WORLD_PROFILE_SCRIPT.Biome.SNOW:
				continue
			if flow < 0.68:
				continue

			var yaw: float = _flow_yaw(world_x, world_z)
			var length: float = 3.0 + flow * 5.5
			var width: float = 0.75 + (1.0 - slope) * 1.4
			var basis: Basis = Basis(Vector3.UP, yaw)
			basis = basis.scaled(Vector3(width, 1.0, length))
			transforms.append(Transform3D(basis, Vector3(local_x, height + 0.045, local_z)))

	_create_multimesh(transforms)


func _create_multimesh(transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return

	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(1.0, 1.0)

	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = plane
	multimesh.instance_count = transforms.size()
	for index: int in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])

	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = "FlowMarks"
	instance.multimesh = multimesh
	instance.material_override = _water_material
	add_child(instance)


func _flow_yaw(world_x: float, world_z: float) -> float:
	var step: float = 2.5
	var left: float = world_profile.sample_height(world_x - step, world_z)
	var right: float = world_profile.sample_height(world_x + step, world_z)
	var down: float = world_profile.sample_height(world_x, world_z - step)
	var up: float = world_profile.sample_height(world_x, world_z + step)
	var downhill: Vector2 = Vector2(left - right, down - up)
	if downhill.length_squared() < 0.001:
		return _hash_unit(int(world_x), int(world_z), 31) * TAU
	return atan2(downhill.x, downhill.y)


func _chunk_world_x() -> float:
	return float(chunk_coord.x) * chunk_size


func _chunk_world_z() -> float:
	return float(chunk_coord.y) * chunk_size


func _hash_unit(x_index: int, z_index: int, salt: int) -> float:
	var hash: int = int(chunk_coord.x * 73856093) ^ int(chunk_coord.y * 19349663) ^ int(x_index * 83492791) ^ int(z_index * 2654435761) ^ int(seed + salt * 374761393)
	hash = (hash ^ (hash >> 13)) * 1274126177
	hash = hash ^ (hash >> 16)
	return float(hash & 0xffff) / 65535.0
