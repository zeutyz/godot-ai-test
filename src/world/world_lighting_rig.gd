class_name WorldLightingRig
extends Node3D

const FOLLOW_CAMERA_VOXEL_GI_SCRIPT = preload("res://src/world/follow_camera_voxel_gi.gd")

var environment: Environment
var sun: DirectionalLight3D
var fill_light: DirectionalLight3D
var voxel_gi: VoxelGI


func _ready() -> void:
	_build_environment()
	_build_sun()
	_build_fill_light()
	_build_streaming_gi()


func _build_environment() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.78, 0.88)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.72, 0.64)
	environment.ambient_light_energy = 1.2
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.62, 0.73, 0.72)
	environment.fog_density = 0.00145
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.08
	environment.tonemap_white = 1.22
	environment.glow_enabled = true
	environment.glow_intensity = 0.16
	environment.glow_bloom = 0.08
	environment.ssao_enabled = true
	environment.ssao_radius = 3.8
	environment.ssao_intensity = 1.35
	environment.ssil_enabled = true
	environment.ssil_radius = 4.6
	environment.ssil_intensity = 0.95
	environment.sdfgi_enabled = true
	environment.sdfgi_energy = 0.82
	environment.sdfgi_cascades = 6
	environment.sdfgi_min_cell_size = 1.5
	world_environment.environment = environment
	add_child(world_environment)


func _build_sun() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "WarmSoftSun"
	sun.rotation_degrees = Vector3(-42.0, -34.0, 0.0)
	sun.light_color = Color(1.0, 0.91, 0.72)
	sun.light_energy = 3.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 340.0
	sun.directional_shadow_split_1 = 0.09
	sun.directional_shadow_split_2 = 0.23
	sun.directional_shadow_split_3 = 0.48
	sun.directional_shadow_blend_splits = true
	sun.shadow_blur = 3.2
	add_child(sun)


func _build_fill_light() -> void:
	fill_light = DirectionalLight3D.new()
	fill_light.name = "CoolSkyFill"
	fill_light.rotation_degrees = Vector3(-22.0, 146.0, 0.0)
	fill_light.light_color = Color(0.55, 0.68, 0.82)
	fill_light.light_energy = 0.42
	fill_light.shadow_enabled = false
	add_child(fill_light)


func _build_streaming_gi() -> void:
	voxel_gi = FOLLOW_CAMERA_VOXEL_GI_SCRIPT.new()
	voxel_gi.name = "StreamingVoxelGIReference"
	voxel_gi.size = Vector3(260.0, 110.0, 260.0)
	voxel_gi.subdiv = VoxelGI.SUBDIV_128
	add_child(voxel_gi)


func get_quality_report() -> Dictionary:
	return {
		"sdfgi": environment != null and environment.sdfgi_enabled,
		"ssao": environment != null and environment.ssao_enabled,
		"ssil": environment != null and environment.ssil_enabled,
		"glow": environment != null and environment.glow_enabled,
		"sun_shadows": sun != null and sun.shadow_enabled,
		"shadow_distance": sun.directional_shadow_max_distance if sun != null else 0.0,
		"voxel_gi_size_x": voxel_gi.size.x if voxel_gi != null else 0.0,
	}
