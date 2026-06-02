extends SceneTree

const WORLD_PROFILE_SCRIPT = preload("res://src/world/world_profile.gd")
const TERRAIN_CHUNK_SCRIPT = preload("res://src/world/terrain_chunk.gd")


func _init() -> void:
	var world_profile: RefCounted = WORLD_PROFILE_SCRIPT.new()
	world_profile.configure(481516, 34.0)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	var chunk: MeshInstance3D = TERRAIN_CHUNK_SCRIPT.new()
	chunk.setup(Vector2i.ZERO, 64.0, 32, world_profile, material)
	var average_normal_y: float = float(chunk.get_average_normal_y())
	print("WORLD_NORMAL_CHECK average_normal_y=%.4f direction=%s" % [
		average_normal_y,
		"up" if average_normal_y > 0.0 else "down",
	])
	chunk.free()
	quit(0 if average_normal_y > 0.0 else 1)
