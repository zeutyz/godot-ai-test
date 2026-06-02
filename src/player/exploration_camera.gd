class_name ExplorationCamera
extends Node3D

@export var move_speed: float = 34.0
@export var sprint_multiplier: float = 2.2
@export var mouse_sensitivity: float = 0.0035
@export var camera_height: float = 28.0
@export var acceleration: float = 10.0     # Suavidade do movimento (quanto maior = mais responsivo)
@export var vertical_speed_multiplier: float = 0.8  # Velocidade de subir/descer (Q/E)

var _yaw: float = 0.0
var _pitch: float = -0.42
var _camera: Camera3D
var _velocity: Vector3 = Vector3.ZERO

var _mouse_captured: bool = true


func _ready() -> void:
	_camera = Camera3D.new()
	add_child(_camera)
	_camera.current = true
	_camera.position = Vector3(0.0, camera_height, 0.0)
	_camera.rotation.x = _pitch
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	# Toggle captura do mouse com botão direito
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_mouse_captured = event.pressed
		
		if _mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Movimento do mouse
	elif event is InputEventMouseMotion and _mouse_captured:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		
		_yaw -= motion.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - motion.relative.y * mouse_sensitivity, -1.2, 0.15)
		
		rotation.y = _yaw
		_camera.rotation.x = _pitch
	
	# ESC para soltar mouse (mantido como backup)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_mouse_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if not _mouse_captured:
		return
	
	# === INPUT DE MOVIMENTO ===
	var input_vector: Vector3 = Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W): input_vector.z -= 1.0
	if Input.is_key_pressed(KEY_S): input_vector.z += 1.0
	if Input.is_key_pressed(KEY_A): input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_vector.x += 1.0
	if Input.is_key_pressed(KEY_Q): input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_E): input_vector.y += 1.0
	
	if input_vector.length_squared() > 0.0:
		input_vector = input_vector.normalized()
	
	var current_speed = move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= sprint_multiplier
	
	# Direção desejada (considerando rotação da câmera)
	var forward = -_camera.global_transform.basis.z
	var right   = _camera.global_transform.basis.x
	
	# Movimento horizontal (mantém o comportamento "no chão" que você tinha)
	var move_dir = (right * input_vector.x + forward * -input_vector.z)
	move_dir.y = 0
	move_dir = move_dir.normalized()
	
	# Movimento vertical (voar com Q/E)
	var vertical_dir = input_vector.y
	
	var target_velocity = (move_dir * current_speed) + (Vector3.UP * vertical_dir * current_speed * vertical_speed_multiplier)
	
	# Suavização (aceleração)
	_velocity = _velocity.lerp(target_velocity, acceleration * delta)
	
	# Aplica movimento
	global_position += _velocity * delta
