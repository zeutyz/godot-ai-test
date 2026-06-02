class_name FollowCameraVoxelGI
extends VoxelGI

@export var fixed_height: float = 32.0
@export var snap_size: float = 32.0


func _process(_delta: float) -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return

	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return

	global_position = Vector3(
			_snap(camera.global_position.x),
			fixed_height,
			_snap(camera.global_position.z))


func _snap(value: float) -> float:
	if snap_size <= 0.0:
		return value
	return floorf(value / snap_size) * snap_size
