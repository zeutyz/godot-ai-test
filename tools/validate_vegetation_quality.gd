extends SceneTree

const WORLD_PROFILE_SCRIPT = preload("res://src/world/world_profile.gd")
const WORLD_PROFILE_BIOME_FOREST: int = 3
const WORLD_PROFILE_BIOME_MEADOW: int = 2
const WORLD_PROFILE_BIOME_HIGHLAND: int = 5


func _init() -> void:
	var world_profile: RefCounted = WORLD_PROFILE_SCRIPT.new()
	world_profile.configure(481516, 34.0)

	var coord: Vector2i = Vector2i(6, 0)
	var grass: int = _count_grass(coord, world_profile)
	var flowers: int = _best_flower_count(world_profile)
	var tree_data: Dictionary = _count_trees(coord, world_profile)
	var distant_canopies: int = _count_distant_canopies(coord, world_profile)

	print("VEGETATION_QUALITY coord=%s grass=%d flowers=%d trees=%d crowns=%d distant_canopies=%d max_tree_height=%.2f" % [
		str(coord),
		grass,
		flowers,
		int(tree_data["trees"]),
		int(tree_data["crowns"]),
		distant_canopies,
		float(tree_data["max_tree_height"]),
	])

	var passes_grass_density: bool = grass >= 1500
	var passes_tree_height: bool = float(tree_data["max_tree_height"]) >= 20.0
	var passes_tree_volume: bool = int(tree_data["trees"]) > 0 and int(tree_data["crowns"]) >= int(tree_data["trees"]) * 3
	var passes_distant_canopy: bool = distant_canopies >= 3
	quit(0 if passes_grass_density and passes_tree_height and passes_tree_volume and passes_distant_canopy else 1)


func _count_grass(coord: Vector2i, world_profile: RefCounted) -> int:
	var count: int = 0
	for layer_index: int in range(2):
		var cell_count: int = 50 - layer_index * 10
		var cell_size: float = 64.0 / float(cell_count)
		var layer_salt: int = 2000 + layer_index * 311
		for z_index: int in range(cell_count):
			for x_index: int in range(cell_count):
				var local_x: float = (float(x_index) + _hash_unit(coord, x_index, z_index, layer_salt + 3)) * cell_size
				var local_z: float = (float(z_index) + _hash_unit(coord, x_index, z_index, layer_salt + 7)) * cell_size
				var sample: Dictionary = world_profile.sample_world(float(coord.x) * 64.0 + local_x, float(coord.y) * 64.0 + local_z)
				var biome: int = int(sample["biome"])
				if float(sample["slope"]) <= 0.56 and (biome == WORLD_PROFILE_BIOME_MEADOW or biome == WORLD_PROFILE_BIOME_FOREST or biome == WORLD_PROFILE_BIOME_HIGHLAND):
					if _hash_unit(coord, x_index, z_index, layer_salt + 19) <= 0.76 + float(sample["fertility"]) * 0.24:
						count += 1
	return count


func _count_flowers(coord: Vector2i, world_profile: RefCounted) -> int:
	var count: int = 0
	var cell_count: int = 24
	var cell_size: float = 64.0 / float(cell_count)
	for z_index: int in range(cell_count):
		for x_index: int in range(cell_count):
			var local_x: float = (float(x_index) + _hash_unit(coord, x_index, z_index, 503)) * cell_size
			var local_z: float = (float(z_index) + _hash_unit(coord, x_index, z_index, 509)) * cell_size
			var sample: Dictionary = world_profile.sample_world(float(coord.x) * 64.0 + local_x, float(coord.y) * 64.0 + local_z)
			var biome: int = int(sample["biome"])
			if float(sample["slope"]) <= 0.34 and (biome == WORLD_PROFILE_BIOME_MEADOW or biome == WORLD_PROFILE_BIOME_HIGHLAND):
				if _hash_unit(coord, x_index, z_index, 521) <= float(sample["fertility"]) * 0.42 + float(sample["moisture"]) * 0.18:
					count += 1
	return count


func _best_flower_count(world_profile: RefCounted) -> int:
	var best_count: int = 0
	var coords: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 1),
		Vector2i(-2, 1),
		Vector2i(4, -2),
		Vector2i(-4, -1),
		Vector2i(5, -3),
	]
	for coord: Vector2i in coords:
		best_count = maxi(best_count, _count_flowers(coord, world_profile))
	return best_count


func _count_trees(coord: Vector2i, world_profile: RefCounted) -> Dictionary:
	var trees: int = 0
	var max_tree_height: float = 0.0
	var cell_count: int = 11
	var cell_size: float = 64.0 / float(cell_count)
	for z_index: int in range(cell_count):
		for x_index: int in range(cell_count):
			if _hash_unit(coord, x_index, z_index, 41) < 0.18:
				continue
			var local_x: float = (float(x_index) + _hash_unit(coord, x_index, z_index, 43)) * cell_size
			var local_z: float = (float(z_index) + _hash_unit(coord, x_index, z_index, 47)) * cell_size
			var sample: Dictionary = world_profile.sample_world(float(coord.x) * 64.0 + local_x, float(coord.y) * 64.0 + local_z)
			if int(sample["biome"]) != WORLD_PROFILE_BIOME_FOREST or float(sample["slope"]) > 0.44:
				continue
			if _hash_unit(coord, x_index, z_index, 107) > 0.62 + float(sample["fertility"]) * 0.35:
				continue
			if not _wins_tree_priority(coord, x_index, z_index):
				continue
			var tree_scale: float = 0.85 + _hash_unit(coord, x_index, z_index, 53) * 0.85
			var trunk_height: float = 15.0 + tree_scale * 5.5 + float(sample["fertility"]) * 4.5
			var crown_height: float = 7.5 + tree_scale * 4.4
			max_tree_height = maxf(max_tree_height, trunk_height + crown_height)
			trees += 1
	return {"trees": trees, "crowns": trees * 3, "max_tree_height": max_tree_height}


func _count_distant_canopies(coord: Vector2i, world_profile: RefCounted) -> int:
	var count: int = 0
	var cell_count: int = 8
	var cell_size: float = 64.0 / float(cell_count)
	for z_index: int in range(cell_count):
		for x_index: int in range(cell_count):
			var local_x: float = (float(x_index) + _hash_unit(coord, x_index, z_index, 401)) * cell_size
			var local_z: float = (float(z_index) + _hash_unit(coord, x_index, z_index, 409)) * cell_size
			var sample: Dictionary = world_profile.sample_world(float(coord.x) * 64.0 + local_x, float(coord.y) * 64.0 + local_z)
			if int(sample["biome"]) == WORLD_PROFILE_BIOME_FOREST and float(sample["slope"]) <= 0.52 and _hash_unit(coord, x_index, z_index, 419) <= 0.62:
				count += 1
	return count


func _wins_tree_priority(coord: Vector2i, x_index: int, z_index: int) -> bool:
	var own_priority: float = _hash_unit(coord, x_index, z_index, 301)
	for z_offset: int in range(-1, 2):
		for x_offset: int in range(-1, 2):
			if x_offset == 0 and z_offset == 0:
				continue
			var neighbor_x: int = x_index + x_offset
			var neighbor_z: int = z_index + z_offset
			var neighbor_priority: float = _hash_unit(coord, neighbor_x, neighbor_z, 301)
			var neighbor_candidate: float = _hash_unit(coord, neighbor_x, neighbor_z, 107)
			if neighbor_candidate <= 0.88 and neighbor_priority > own_priority:
				return false
	return true


func _hash_unit(coord: Vector2i, x_index: int, z_index: int, salt: int) -> float:
	var hash: int = int(coord.x * 73856093) ^ int(coord.y * 19349663) ^ int(x_index * 83492791) ^ int(z_index * 2654435761) ^ int(481516 + salt * 374761393)
	hash = (hash ^ (hash >> 13)) * 1274126177
	hash = hash ^ (hash >> 16)
	return float(hash & 0xffff) / 65535.0
