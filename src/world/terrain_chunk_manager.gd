class_name TerrainChunkManager
extends Node3D

const TERRAIN_CHUNK_SCRIPT = preload("res://src/world/terrain_chunk.gd")
const WORLD_PROFILE_SCRIPT = preload("res://src/world/world_profile.gd")
const PROCEDURAL_VEGETATION_SCRIPT = preload("res://src/world/procedural_vegetation.gd")
const PROCEDURAL_WATER_FEATURES_SCRIPT = preload("res://src/world/procedural_water_features.gd")
const TERRAIN_SHADER = preload("res://shaders/terrain_painterly.gdshader")

@export var chunk_size: float = 64.0
@export var chunk_resolution: int = 80
@export var view_radius: int = 4
@export var unload_radius: int = 6
@export var height_scale: float = 34.0
@export var seed: int = 481516
@export var mid_lod_resolution: int = 40
@export var far_lod_resolution: int = 18
@export var chunks_per_frame: int = 2

var _world_profile: RefCounted
var _chunks: Dictionary = {}
var _chunk_lods: Dictionary = {}
var _terrain_material: ShaderMaterial
var _current_center_coord: Vector2i = Vector2i(999999, 999999)
var _lod_counts: Array[int] = [0, 0, 0]
var _pending_chunks: Array[Dictionary] = []
var _total_queued_chunks: int = 0
var _generated_chunks: int = 0
var _status_message: String = "preparando mundo"
var _normal_average_y: float = 1.0
var _vegetation_metrics: Dictionary = {
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


func _ready() -> void:
	_status_message = "preparando perfil de mundo e mapas derivados"
	_world_profile = WORLD_PROFILE_SCRIPT.new()
	_world_profile.configure(seed, height_scale)

	_terrain_material = ShaderMaterial.new()
	_terrain_material.shader = TERRAIN_SHADER

	call_deferred("_update_streaming_center", Vector3.ZERO)


func _process(_delta: float) -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return

	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		_process_generation_queue()
		return

	_update_streaming_center(camera.global_position)
	_process_generation_queue()


func _update_streaming_center(world_position: Vector3) -> void:
	var center_coord: Vector2i = Vector2i(
			floori(world_position.x / chunk_size),
			floori(world_position.z / chunk_size))
	if center_coord == _current_center_coord:
		return

	_current_center_coord = center_coord
	_rebuild_visible_chunks(center_coord)


func _rebuild_visible_chunks(center_coord: Vector2i) -> void:
	_lod_counts = [0, 0, 0]
	for z_offset: int in range(-view_radius, view_radius + 1):
		for x_offset: int in range(-view_radius, view_radius + 1):
			var coord: Vector2i = center_coord + Vector2i(x_offset, z_offset)
			var lod_level: int = _lod_for_offset(x_offset, z_offset)
			_lod_counts[lod_level] += 1
			if not _chunks.has(coord):
				_queue_chunk(coord, lod_level)
			elif int(_chunk_lods[coord]) != lod_level:
				_replace_chunk(coord, lod_level)

	for key: Variant in _chunks.keys():
		var coord_key: Vector2i = key as Vector2i
		if _chunk_distance(coord_key, center_coord) > unload_radius:
			var chunk: Node = _chunks[coord_key] as Node
			_chunks.erase(coord_key)
			_chunk_lods.erase(coord_key)
			chunk.queue_free()


func _replace_chunk(coord: Vector2i, lod_level: int) -> void:
	var old_chunk: Node = _chunks[coord] as Node
	_chunks.erase(coord)
	_chunk_lods.erase(coord)
	old_chunk.queue_free()
	_queue_chunk(coord, lod_level)


func _queue_chunk(coord: Vector2i, lod_level: int) -> void:
	for pending: Dictionary in _pending_chunks:
		if Vector2i(pending["coord"]) == coord:
			pending["lod"] = lod_level
			return

	_pending_chunks.append({"coord": coord, "lod": lod_level})
	_total_queued_chunks += 1
	_status_message = "enfileirando terreno %d, %d LOD%d" % [coord.x, coord.y, lod_level]


func _process_generation_queue() -> void:
	var generated_this_frame: int = 0
	while generated_this_frame < chunks_per_frame and not _pending_chunks.is_empty():
		var next_chunk: Dictionary = _pending_chunks.pop_front()
		var coord: Vector2i = Vector2i(next_chunk["coord"])
		var lod_level: int = int(next_chunk["lod"])
		if _chunks.has(coord):
			continue
		_status_message = "gerando relevo e normais %d, %d LOD%d" % [coord.x, coord.y, lod_level]
		_create_chunk(coord, lod_level)
		generated_this_frame += 1
		_generated_chunks += 1
		_status_message = "populando biomas e vegetacao %d, %d LOD%d" % [coord.x, coord.y, lod_level]


func _create_chunk(coord: Vector2i, lod_level: int) -> void:
	var chunk: MeshInstance3D = TERRAIN_CHUNK_SCRIPT.new()
	add_child(chunk)
	chunk.setup(coord, chunk_size, _resolution_for_lod(lod_level), _world_profile, _terrain_material)
	_chunks[coord] = chunk
	_chunk_lods[coord] = lod_level
	if chunk.has_method("get_average_normal_y"):
		_normal_average_y = float(chunk.get_average_normal_y())

	if lod_level <= 2:
		var vegetation: Node3D = PROCEDURAL_VEGETATION_SCRIPT.new()
		vegetation.name = "Vegetation_%d_%d_LOD%d" % [coord.x, coord.y, lod_level]
		chunk.add_child(vegetation)
		vegetation.setup(coord, chunk_size, _world_profile, seed, lod_level)
		_accumulate_vegetation_metrics(vegetation)

	if lod_level <= 1:
		var water_features: Node3D = PROCEDURAL_WATER_FEATURES_SCRIPT.new()
		water_features.name = "WaterFeatures_%d_%d_LOD%d" % [coord.x, coord.y, lod_level]
		chunk.add_child(water_features)
		water_features.setup(coord, chunk_size, _world_profile, seed, lod_level)


func _lod_for_offset(x_offset: int, z_offset: int) -> int:
	var distance: int = maxi(absi(x_offset), absi(z_offset))
	if distance <= 1:
		return 0
	if distance <= 2:
		return 1
	return 2


func _chunk_distance(a: Vector2i, b: Vector2i) -> int:
	var delta: Vector2i = a - b
	return maxi(absi(delta.x), absi(delta.y))


func _resolution_for_lod(lod_level: int) -> int:
	if lod_level <= 0:
		return chunk_resolution
	if lod_level == 1:
		return mid_lod_resolution
	return far_lod_resolution


func get_world_profile() -> RefCounted:
	return _world_profile


func get_active_chunk_count() -> int:
	return _chunks.size()


func get_current_center_coord() -> Vector2i:
	return _current_center_coord


func get_lod_counts() -> Array[int]:
	return _lod_counts.duplicate()


func get_generation_progress() -> float:
	if _total_queued_chunks <= 0:
		return 1.0
	return clampf(float(_generated_chunks) / float(_total_queued_chunks), 0.0, 1.0)


func get_pending_chunk_count() -> int:
	return _pending_chunks.size()


func get_status_message() -> String:
	return _status_message


func get_average_normal_y() -> float:
	return _normal_average_y


func get_vegetation_metrics() -> Dictionary:
	return _vegetation_metrics.duplicate()


func _accumulate_vegetation_metrics(vegetation: Node) -> void:
	if not vegetation.has_method("get_metrics"):
		return

	var metrics: Dictionary = vegetation.get_metrics()
	_vegetation_metrics["grass"] = int(_vegetation_metrics["grass"]) + int(metrics["grass"])
	_vegetation_metrics["flowers"] = int(_vegetation_metrics["flowers"]) + int(metrics["flowers"])
	_vegetation_metrics["trees"] = int(_vegetation_metrics["trees"]) + int(metrics["trees"])
	_vegetation_metrics["crowns"] = int(_vegetation_metrics["crowns"]) + int(metrics["crowns"])
	_vegetation_metrics["reeds"] = int(_vegetation_metrics["reeds"]) + int(metrics["reeds"])
	_vegetation_metrics["bushes"] = int(_vegetation_metrics["bushes"]) + int(metrics["bushes"])
	_vegetation_metrics["rocks"] = int(_vegetation_metrics["rocks"]) + int(metrics["rocks"])
	_vegetation_metrics["distant_canopies"] = int(_vegetation_metrics["distant_canopies"]) + int(metrics["distant_canopies"])
	_vegetation_metrics["max_tree_height"] = maxf(float(_vegetation_metrics["max_tree_height"]), float(metrics["max_tree_height"]))
