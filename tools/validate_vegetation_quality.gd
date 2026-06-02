extends SceneTree

const WORLD_PROFILE_SCRIPT = preload("res://src/world/world_profile.gd")
const PROCEDURAL_VEGETATION_SCRIPT = preload("res://src/world/procedural_vegetation.gd")


func _init() -> void:
	var world_profile: RefCounted = WORLD_PROFILE_SCRIPT.new()
	world_profile.configure(481516, 34.0)

	var best_grass: int = 0
	var best_trees: int = 0
	var best_crowns: int = 0
	var best_tree_height: float = 0.0
	var best_coord: Vector2i = Vector2i.ZERO

	for z_coord: int in range(-6, 7):
		for x_coord: int in range(-6, 7):
			var coord: Vector2i = Vector2i(x_coord, z_coord)
			var vegetation: Node3D = PROCEDURAL_VEGETATION_SCRIPT.new()
			get_root().add_child(vegetation)
			vegetation.setup(coord, 64.0, world_profile, 481516, 0)
			var metrics: Dictionary = vegetation.get_metrics()
			var grass: int = int(metrics["grass"])
			var trees: int = int(metrics["trees"])
			var crowns: int = int(metrics["crowns"])
			var tree_height: float = float(metrics["max_tree_height"])
			if grass + trees * 120 > best_grass + best_trees * 120:
				best_grass = grass
				best_trees = trees
				best_crowns = crowns
				best_tree_height = tree_height
				best_coord = coord
			vegetation.free()

	print("VEGETATION_QUALITY coord=%s grass=%d trees=%d crowns=%d max_tree_height=%.2f" % [
		str(best_coord),
		best_grass,
		best_trees,
		best_crowns,
		best_tree_height,
	])

	var passes_grass_density: bool = best_grass >= 1500
	var passes_tree_height: bool = best_tree_height >= 20.0
	var passes_tree_volume: bool = best_trees > 0 and best_crowns >= best_trees * 3
	quit(0 if passes_grass_density and passes_tree_height and passes_tree_volume else 1)
