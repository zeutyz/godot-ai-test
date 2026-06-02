extends Node3D

const TERRAIN_CHUNK_MANAGER_SCRIPT = preload("res://src/world/terrain_chunk_manager.gd")
const EXPLORATION_CAMERA_SCRIPT = preload("res://src/player/exploration_camera.gd")
const WORLD_DEBUG_HUD_SCRIPT = preload("res://src/ui/world_debug_hud.gd")
const FOLLOW_CAMERA_PLANE_SCRIPT = preload("res://src/world/follow_camera_plane.gd")
const LOADING_OVERLAY_SCRIPT = preload("res://src/ui/loading_overlay.gd")
const WATER_SHADER = preload("res://shaders/water_painterly.gdshader")
const FOLLOW_CAMERA_VOXEL_GI_SCRIPT = preload("res://src/world/follow_camera_voxel_gi.gd")


func _ready() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.78, 0.88)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.72, 0.64)
	environment.ambient_light_energy = 1.15
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.62, 0.73, 0.72)
	environment.fog_density = 0.0016
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.18
	environment.ssao_enabled = true
	environment.ssao_radius = 3.0
	environment.ssao_intensity = 1.25
	environment.ssil_enabled = true
	environment.ssil_radius = 4.0
	environment.ssil_intensity = 0.85
	environment.sdfgi_enabled = true
	environment.sdfgi_energy = 0.75
	world_environment.environment = environment
	add_child(world_environment)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42.0, -34.0, 0.0)
	sun.light_energy = 3.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 260.0
	add_child(sun)

	var gi_probe: VoxelGI = FOLLOW_CAMERA_VOXEL_GI_SCRIPT.new()
	gi_probe.name = "StreamingVoxelGIReference"
	gi_probe.size = Vector3(220.0, 90.0, 220.0)
	gi_probe.subdiv = VoxelGI.SUBDIV_128
	add_child(gi_probe)

	var terrain: Node3D = TERRAIN_CHUNK_MANAGER_SCRIPT.new()
	terrain.name = "TerrainChunkManager"
	add_child(terrain)

	var water: MeshInstance3D = FOLLOW_CAMERA_PLANE_SCRIPT.new()
	water.name = "WaterPlane"
	var water_mesh: PlaneMesh = PlaneMesh.new()
	water_mesh.size = Vector2(520.0, 520.0)
	water.mesh = water_mesh
	water.position = Vector3(0.0, -3.45, 0.0)
	var water_material: ShaderMaterial = ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	water.material_override = water_material
	add_child(water)

	var camera_rig: Node3D = EXPLORATION_CAMERA_SCRIPT.new()
	camera_rig.name = "ExplorationCamera"
	camera_rig.position = Vector3(32.0, 0.0, 96.0)
	add_child(camera_rig)

	var debug_hud: CanvasLayer = WORLD_DEBUG_HUD_SCRIPT.new()
	debug_hud.name = "WorldDebugHud"
	add_child(debug_hud)
	debug_hud.setup(terrain)

	var loading_overlay: CanvasLayer = LOADING_OVERLAY_SCRIPT.new()
	loading_overlay.name = "LoadingOverlay"
	add_child(loading_overlay)
	loading_overlay.setup(terrain)
