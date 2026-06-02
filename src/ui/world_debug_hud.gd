class_name WorldDebugHud
extends CanvasLayer

var terrain_manager: Node
var _label: Label


func setup(p_terrain_manager: Node) -> void:
	terrain_manager = p_terrain_manager


func _ready() -> void:
	_label = Label.new()
	_label.name = "WorldDebugLabel"
	_label.position = Vector2(16.0, 16.0)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.88))
	_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.07, 0.06))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)


func _process(_delta: float) -> void:
	if terrain_manager == null or _label == null:
		return

	var viewport: Viewport = get_viewport()
	if viewport == null:
		return

	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		_label.text = "mundo procedural\ncamera: indisponivel"
		return

	var world_profile: RefCounted = terrain_manager.get_world_profile()
	if world_profile == null:
		_label.text = "mundo procedural\nperfil: carregando"
		return

	var world_position: Vector3 = camera.global_position
	var world_sample: Dictionary = world_profile.sample_world(world_position.x, world_position.z)
	var biome: int = int(world_sample["biome"])
	var height: float = float(world_sample["height"])
	var moisture: float = float(world_sample["moisture"])
	var flow: float = float(world_sample["flow"])
	var center_coord: Vector2i = terrain_manager.get_current_center_coord()
	var active_chunks: int = terrain_manager.get_active_chunk_count()
	var lod_counts: Array[int] = terrain_manager.get_lod_counts()
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var memory_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var normal_y: float = terrain_manager.get_average_normal_y()
	var progress: float = terrain_manager.get_generation_progress()
	var pending: int = terrain_manager.get_pending_chunk_count()
	var vegetation_metrics: Dictionary = terrain_manager.get_vegetation_metrics()
	var grass_count: int = int(vegetation_metrics["grass"])
	var tree_count: int = int(vegetation_metrics["trees"])
	var crown_count: int = int(vegetation_metrics["crowns"])
	var max_tree_height: float = float(vegetation_metrics["max_tree_height"])

	_label.text = "mundo procedural\nchunk: %d, %d | ativos: %d | pend: %d | lod: %d/%d/%d\nbioma: %s\naltura: %.1f | umidade: %.2f | fluxo: %.2f\nveg: grama %d | arvores %d | copas %d | max %.1fm\n%.0f fps | proc %.2f ms | ram %.1f MB | normalY %.2f | load %.0f%%" % [
		center_coord.x,
		center_coord.y,
		active_chunks,
		pending,
		int(lod_counts[0]),
		int(lod_counts[1]),
		int(lod_counts[2]),
		world_profile.biome_name(biome),
		height,
		moisture,
		flow,
		grass_count,
		tree_count,
		crown_count,
		max_tree_height,
		fps,
		process_ms,
		memory_mb,
		normal_y,
		progress * 100.0,
	]
