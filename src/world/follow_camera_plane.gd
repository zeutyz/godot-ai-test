class_name FollowCameraPlane
extends MeshInstance3D

@export var fixed_height: float = -3.45


func _process(_delta: float) -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return

	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return

	global_position = Vector3(camera.global_position.x, fixed_height, camera.global_position.z)
