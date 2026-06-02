extends Node3D

const TERRAIN_CHUNK_MANAGER_SCRIPT = preload("res://src/world/terrain_chunk_manager.gd")
const EXPLORATION_CAMERA_SCRIPT = preload("res://src/player/exploration_camera.gd")
const WORLD_DEBUG_HUD_SCRIPT = preload("res://src/ui/world_debug_hud.gd")
const FOLLOW_CAMERA_PLANE_SCRIPT = preload("res://src/world/follow_camera_plane.gd")
const LOADING_OVERLAY_SCRIPT = preload("res://src/ui/loading_overlay.gd")
const WATER_SHADER = preload("res://shaders/water_painterly.gdshader")
const WORLD_LIGHTING_RIG_SCRIPT = preload("res://src/world/world_lighting_rig.gd")


func _ready() -> void:
	var lighting: Node3D = WORLD_LIGHTING_RIG_SCRIPT.new()
	lighting.name = "WorldLightingRig"
	add_child(lighting)

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
