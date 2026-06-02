class_name WorldProfile
extends RefCounted

enum Biome {
	WATER,
	BEACH,
	MEADOW,
	FOREST,
	WETLAND,
	HIGHLAND,
	ROCK,
	SNOW
}

const SEA_LEVEL: float = -3.5

var height_scale: float = 24.0
var terrain_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var heat_noise: FastNoiseLite
var fertility_noise: FastNoiseLite


func configure(seed: int, p_height_scale: float) -> void:
	height_scale = p_height_scale

	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = seed
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = 5
	terrain_noise.fractal_lacunarity = 2.15
	terrain_noise.fractal_gain = 0.48

	moisture_noise = FastNoiseLite.new()
	moisture_noise.seed = seed + 9173
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moisture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	moisture_noise.fractal_octaves = 4
	moisture_noise.fractal_lacunarity = 2.0
	moisture_noise.fractal_gain = 0.52

	heat_noise = FastNoiseLite.new()
	heat_noise.seed = seed - 421
	heat_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	heat_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	heat_noise.fractal_octaves = 3
	heat_noise.fractal_lacunarity = 2.0
	heat_noise.fractal_gain = 0.5

	fertility_noise = FastNoiseLite.new()
	fertility_noise.seed = seed + 23167
	fertility_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	fertility_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	fertility_noise.fractal_octaves = 3
	fertility_noise.fractal_lacunarity = 2.2
	fertility_noise.fractal_gain = 0.46


func sample_height(world_x: float, world_z: float) -> float:
	var continental: float = terrain_noise.get_noise_2d(world_x * 0.018, world_z * 0.018)
	var broad_valleys: float = terrain_noise.get_noise_2d(world_x * 0.006 - 800.0, world_z * 0.006 + 430.0)
	var detail: float = terrain_noise.get_noise_2d(world_x * 0.075 + 93.0, world_z * 0.075 - 41.0)
	var ridges: float = 1.0 - absf(terrain_noise.get_noise_2d(world_x * 0.030 - 211.0, world_z * 0.030 + 37.0))
	var mountain_mask: float = smoothstep(0.08, 0.62, continental * 0.5 + broad_valleys * 0.5)
	var valley_cut: float = smoothstep(-0.58, -0.08, broad_valleys)
	var shaped: float = continental * 0.52 + detail * 0.13 + ridges * ridges * mountain_mask * 0.88
	shaped = shaped * lerpf(0.72, 1.22, mountain_mask) - (1.0 - valley_cut) * 0.28
	return shaped * height_scale


func sample_moisture(world_x: float, world_z: float, height: float) -> float:
	var base_moisture: float = moisture_noise.get_noise_2d(world_x * 0.012 - 130.0, world_z * 0.012 + 80.0)
	var valley_bonus: float = clampf((7.0 - height) / 24.0, 0.0, 0.48)
	var normalized: float = clampf(base_moisture * 0.5 + 0.5 + valley_bonus, 0.0, 1.0)
	return normalized


func sample_heat(world_x: float, world_z: float, height: float) -> float:
	var latitude: float = 1.0 - clampf(absf(world_z) / 900.0, 0.0, 0.72)
	var weather: float = heat_noise.get_noise_2d(world_x * 0.008 + 55.0, world_z * 0.008 - 12.0) * 0.16
	var altitude_cooling: float = clampf(height / maxf(height_scale, 0.01), 0.0, 1.0) * 0.38
	return clampf(latitude + weather - altitude_cooling, 0.0, 1.0)


func sample_slope(world_x: float, world_z: float) -> float:
	var sample_step: float = 2.0
	var left: float = sample_height(world_x - sample_step, world_z)
	var right: float = sample_height(world_x + sample_step, world_z)
	var down: float = sample_height(world_x, world_z - sample_step)
	var up: float = sample_height(world_x, world_z + sample_step)
	var gradient: Vector2 = Vector2(right - left, up - down) / (sample_step * 2.0)
	return clampf(gradient.length() / 1.35, 0.0, 1.0)


func sample_fertility(world_x: float, world_z: float, moisture: float, slope: float) -> float:
	var base_fertility: float = fertility_noise.get_noise_2d(world_x * 0.028 + 19.0, world_z * 0.028 - 71.0)
	var soil: float = base_fertility * 0.5 + 0.5
	var slope_penalty: float = 1.0 - clampf(slope * 1.35, 0.0, 1.0)
	return clampf((soil * 0.55 + moisture * 0.45) * slope_penalty, 0.0, 1.0)


func sample_flow(world_x: float, world_z: float, height: float, moisture: float, slope: float) -> float:
	var valley_factor: float = clampf((6.0 - height) / 14.0, 0.0, 1.0)
	var channel_noise: float = moisture_noise.get_noise_2d(world_x * 0.045 + 300.0, world_z * 0.045 - 110.0)
	var channel: float = smoothstep(0.48, 0.78, channel_noise * 0.5 + 0.5)
	var flow: float = moisture * 0.48 + valley_factor * 0.38 + channel * 0.26 - slope * 0.28
	if height <= SEA_LEVEL + 0.6:
		flow += 0.25
	return clampf(flow, 0.0, 1.0)


func sample_world(world_x: float, world_z: float) -> Dictionary:
	var height: float = sample_height(world_x, world_z)
	var slope: float = sample_slope(world_x, world_z)
	var moisture: float = sample_moisture(world_x, world_z, height)
	var heat: float = sample_heat(world_x, world_z, height)
	var fertility: float = sample_fertility(world_x, world_z, moisture, slope)
	var flow: float = sample_flow(world_x, world_z, height, moisture, slope)
	var biome: int = classify_biome(height, slope, moisture, heat)
	return {
		"height": height,
		"slope": slope,
		"moisture": moisture,
		"heat": heat,
		"fertility": fertility,
		"flow": flow,
		"biome": biome,
	}


func sample_biome(world_x: float, world_z: float) -> int:
	var height: float = sample_height(world_x, world_z)
	var slope: float = sample_slope(world_x, world_z)
	var moisture: float = sample_moisture(world_x, world_z, height)
	var heat: float = sample_heat(world_x, world_z, height)
	return classify_biome(height, slope, moisture, heat)


func classify_biome(height: float, slope: float, moisture: float, heat: float) -> int:
	if height <= SEA_LEVEL:
		return Biome.WATER
	if height <= SEA_LEVEL + 2.2:
		return Biome.BEACH
	if height > height_scale * 0.72:
		return Biome.SNOW
	if slope > 0.68 or height > height_scale * 0.54:
		return Biome.ROCK
	if height > height_scale * 0.28:
		return Biome.HIGHLAND
	if moisture > 0.76 and heat > 0.35:
		return Biome.WETLAND
	if moisture > 0.47:
		return Biome.FOREST
	return Biome.MEADOW


func biome_name(biome: int) -> String:
	match biome:
		Biome.WATER:
			return "agua"
		Biome.BEACH:
			return "praia"
		Biome.MEADOW:
			return "campo"
		Biome.FOREST:
			return "floresta"
		Biome.WETLAND:
			return "brejo"
		Biome.HIGHLAND:
			return "planalto"
		Biome.ROCK:
			return "rocha"
		Biome.SNOW:
			return "neve"
		_:
			return "desconhecido"


func color_for_biome(biome: int, height: float, moisture: float) -> Color:
	match biome:
		Biome.WATER:
			return Color(0.23, 0.42, 0.55)
		Biome.BEACH:
			return Color(0.72, 0.66, 0.43)
		Biome.MEADOW:
			return Color(0.36, 0.56, 0.24).lerp(Color(0.58, 0.70, 0.30), moisture * 0.45)
		Biome.FOREST:
			return Color(0.18, 0.36, 0.20).lerp(Color(0.30, 0.52, 0.24), moisture * 0.34)
		Biome.WETLAND:
			return Color(0.28, 0.45, 0.31)
		Biome.HIGHLAND:
			return Color(0.55, 0.61, 0.34)
		Biome.ROCK:
			return Color(0.49, 0.47, 0.41).lerp(Color(0.38, 0.38, 0.36), clampf(height / height_scale, 0.0, 1.0))
		Biome.SNOW:
			return Color(0.86, 0.88, 0.82)
		_:
			return Color(0.45, 0.62, 0.31)


func blended_color_for_world(world_x: float, world_z: float) -> Color:
	var center: Dictionary = sample_world(world_x, world_z)
	var color_sum: Color = color_for_biome(int(center["biome"]), float(center["height"]), float(center["moisture"])) * 0.42
	var weight_sum: float = 0.42
	var sample_radius: float = 5.5
	var offsets: Array[Vector2] = [
		Vector2(sample_radius, 0.0),
		Vector2(-sample_radius, 0.0),
		Vector2(0.0, sample_radius),
		Vector2(0.0, -sample_radius),
		Vector2(sample_radius * 0.7, sample_radius * 0.7),
		Vector2(-sample_radius * 0.7, -sample_radius * 0.7),
	]

	for offset: Vector2 in offsets:
		var sample: Dictionary = sample_world(world_x + offset.x, world_z + offset.y)
		var height: float = float(sample["height"])
		var moisture: float = float(sample["moisture"])
		var biome: int = int(sample["biome"])
		var sample_weight: float = 0.097
		color_sum += color_for_biome(biome, height, moisture) * sample_weight
		weight_sum += sample_weight

	var blended: Color = color_sum / weight_sum
	var fertility: float = float(center["fertility"])
	var flow: float = float(center["flow"])
	blended = blended.lerp(Color(0.24, 0.42, 0.24), fertility * 0.08)
	blended = blended.lerp(Color(0.24, 0.38, 0.35), flow * 0.08)
	return blended
