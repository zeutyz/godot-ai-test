extends SceneTree

const WORLD_PROFILE_SCRIPT = preload("res://src/world/world_profile.gd")


func _init() -> void:
	var world_profile: RefCounted = WORLD_PROFILE_SCRIPT.new()
	world_profile.configure(481516, 34.0)

	var max_delta: float = 0.0
	var sample_count: int = 0
	var step: float = 8.0

	for z_index: int in range(-12, 13):
		for x_index: int in range(-12, 13):
			var world_x: float = float(x_index) * step
			var world_z: float = float(z_index) * step
			var color_a: Color = world_profile.blended_color_for_world(world_x, world_z)
			var color_b: Color = world_profile.blended_color_for_world(world_x + step, world_z)
			var color_c: Color = world_profile.blended_color_for_world(world_x, world_z + step)
			max_delta = maxf(max_delta, _color_delta(color_a, color_b))
			max_delta = maxf(max_delta, _color_delta(color_a, color_c))
			sample_count += 2

	print("BIOME_BLEND_CHECK samples=%d max_delta=%.4f" % [sample_count, max_delta])
	quit(0 if max_delta < 0.42 else 1)


func _color_delta(a: Color, b: Color) -> float:
	var diff: Vector3 = Vector3(a.r - b.r, a.g - b.g, a.b - b.b)
	return diff.length()
