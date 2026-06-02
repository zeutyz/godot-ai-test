class_name TerrainChunkManager
extends Node3D

const TERRAIN_CHUNK_SCRIPT = preload("res://src/world/terrain_chunk.gd")
const WORLD_PROFILE_SCRIPT = preload("res://src/world/world_profile.gd")
const PROCEDURAL_VEGETATION_SCRIPT = preload("res://src/world/procedural_vegetation.gd")
const PROCEDURAL_WATER_FEATURES_SCRIPT = preload("res://src/world/procedural_water_features.gd")
const TERRAIN_SHADER = preload("res://shaders/terrain_painterly.gdshader")

@export var chunk_size: float = 64.0
@export var chunk_resolution: int = 80
@export var view_radius: int = 5 
@export var unload_radius: int = 8 
@export var height_scale: float = 45.0 
@export var seed: int = 481516
@export var chunks_per_frame: int = 1

var _world_profile: RefCounted
var _chunks: Dictionary = {}
var _chunk_lods: Dictionary = {}
var _terrain_material: ShaderMaterial
var _current_center_coord: Vector2i = Vector2i(999999, 999999)

var _pending_chunks: Array[Dictionary] = []
var _active_async_tasks: Dictionary = {}
var _generated_chunks: int = 0
var _status_message: String = "preparando mundo"


func _ready() -> void:
	_status_message = "preparando perfil de mundo e mapas"
	_world_profile = WORLD_PROFILE_SCRIPT.new()
	_world_profile.configure(seed, height_scale)
	_terrain_material = ShaderMaterial.new()
	_terrain_material.shader = TERRAIN_SHADER
	call_deferred("_update_streaming_center", Vector3.ZERO)


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
	if camera:
		_update_streaming_center(camera.global_position)
	_process_generation_queue()


func _update_streaming_center(world_position: Vector3) -> void:
	var center_coord: Vector2i = Vector2i(floori(world_position.x / chunk_size), floori(world_position.z / chunk_size))
	if center_coord == _current_center_coord:
		return
	_current_center_coord = center_coord
	_rebuild_visible_chunks(center_coord)


func _rebuild_visible_chunks(center_coord: Vector2i) -> void:
	for z_offset: int in range(-view_radius, view_radius + 1):
		for x_offset: int in range(-view_radius, view_radius + 1):
			var coord: Vector2i = center_coord + Vector2i(x_offset, z_offset)
			if not _chunks.has(coord) and not _active_async_tasks.has(coord):
				_queue_chunk(coord, 0)

	for key: Variant in _chunks.keys():
		var coord_key: Vector2i = key as Vector2i
		if _chunk_distance(coord_key, center_coord) > unload_radius:
			if _active_async_tasks.has(coord_key):
				continue
			var chunk: Node = _chunks[coord_key] as Node
			_chunks.erase(coord_key)
			_chunk_lods.erase(coord_key)
			chunk.queue_free()


func _queue_chunk(coord: Vector2i, lod_level: int) -> void:
	for pending: Dictionary in _pending_chunks:
		if Vector2i(pending["coord"]) == coord:
			return
	_pending_chunks.append({"coord": coord, "lod": lod_level})
	_status_message = "enfileirando terreno %d, %d" % [coord.x, coord.y]


func _process_generation_queue() -> void:
	var completed_coords: Array[Vector2i] = []
	for coord: Vector2i in _active_async_tasks.keys():
		var task_info: Dictionary = _active_async_tasks[coord]
		if WorkerThreadPool.is_task_completed(task_info["task_id"]):
			var chunk: TerrainChunk = task_info["chunk"]
			
			chunk.finalize_mesh_on_main_thread()
			if task_info["vegetation"] != null:
				task_info["vegetation"].finalize_vegetation_on_main_thread()
				
			_generated_chunks += 1
			completed_coords.append(coord)
			_status_message = "relevo e vegetacao concluidos para %d, %d" % [coord.x, coord.y]

	for coord: Vector2i in completed_coords:
		_active_async_tasks.erase(coord)

	if not _pending_chunks.is_empty() and _active_async_tasks.size() < chunks_per_frame:
		var next_chunk: Dictionary = _pending_chunks.pop_front()
		var coord: Vector2i = Vector2i(next_chunk["coord"])
		
		if not _chunks.has(coord) and not _active_async_tasks.has(coord):
			_status_message = "despachando geracao assincrona %d, %d" % [coord.x, coord.y]
			_start_async_chunk_generation(coord, int(next_chunk["lod"]))


func _start_async_chunk_generation(coord: Vector2i, lod_level: int) -> void:
	var chunk: TerrainChunk = TERRAIN_CHUNK_SCRIPT.new()
	add_child(chunk)
	chunk.setup(coord, chunk_size, chunk_resolution, _world_profile, _terrain_material)
	
	_chunks[coord] = chunk
	_chunk_lods[coord] = lod_level

	var vegetation: ProceduralVegetation = PROCEDURAL_VEGETATION_SCRIPT.new()
	chunk.add_child(vegetation)
	vegetation.setup(coord, chunk_size, _world_profile, seed, lod_level)

	var async_callable: Callable = func():
		chunk.generate_data_offline()
		vegetation.generate_vegetation_from_faces(chunk.faces_positions, chunk.faces_normals)

	var task_id: int = WorkerThreadPool.add_task(async_callable, 1)
	_active_async_tasks[coord] = {
		"task_id": task_id,
		"chunk": chunk,
		"vegetation": vegetation
	}


func _chunk_distance(a: Vector2i, b: Vector2i) -> int:
	var delta: Vector2i = a - b
	return maxi(absi(delta.x), absi(delta.y))


# --- INTERFACES PÚBLICAS REINTRODUZIDAS PARA CORREÇÃO DO HUD ---

func get_world_profile() -> RefCounted:
	return _world_profile


func get_active_chunk_count() -> int:
	return _chunks.size()


func get_current_center_coord() -> Vector2i:
	return _current_center_coord


func get_pending_chunk_count() -> int:
	return _pending_chunks.size() + _active_async_tasks.size()


func get_status_message() -> String:
	return _status_message


func get_generation_progress() -> float:
	var total: int = _generated_chunks + _pending_chunks.size() + _active_async_tasks.size()
	if total == 0:
		return 1.0
	return float(_generated_chunks) / float(total)


func get_lod_counts() -> Array[int]:
	return [_chunks.size(), 0, 0]


func get_average_normal_y() -> float:
	return 1.0


func get_vegetation_metrics() -> Dictionary:
	var total_grass: int = 0
	var total_trees: int = 0
	var max_height: float = 0.0
	
	for key: Variant in _chunks.keys():
		var chunk: Node = _chunks[key] as Node
		for child: Node in chunk.get_children():
			if child.has_method("get_metrics"):
				var m: Dictionary = child.get_metrics()
				total_grass += int(m.get("grass", 0))
				total_trees += int(m.get("trees", 0))
				max_height = maxf(max_height, float(m.get("max_tree_height", 0.0)))
				
	return {
		"grass": total_grass,
		"flowers": 0,
		"trees": total_trees,
		"crowns": total_trees * 4,
		"reeds": 0,
		"bushes": 0,
		"rocks": 0,
		"distant_canopies": 0,
		"max_tree_height": max_height
	}
