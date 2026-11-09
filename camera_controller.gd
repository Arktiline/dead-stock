
extends Node3D

@export_category("Movement")
@export var move_speed: float = 12.0
@export var fast_move_multiplier: float = 2.0
@export var slow_move_multiplier: float = 0.5
@export var rotation_speed: float = 1.5

@export_category("Zoom")
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 7.0
@export var max_zoom: float = 32.0
@export var zoom_smoothing: float = 8.0

@export_category("Mouse Panning")
@export var pan_sensitivity: float = 0.0015

@onready var camera: Camera3D = $Camera3D

var target_zoom: float = 18.0
var dragging: bool = false


func _ready() -> void:
	camera.make_current()
	target_zoom = camera.size


func _process(delta: float) -> void:
	handle_movement(delta)
	handle_rotation(delta)
	handle_zoom(delta)


func handle_movement(delta: float) -> void:
	var input := Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input.y += 1.0
	if Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input.x += 1.0

	if input.length_squared() > 0.0:
		input = input.normalized()

		var direction := global_transform.basis * Vector3(
			input.x, 0.0, input.y
		)

		var speed := move_speed

		if Input.is_key_pressed(KEY_SHIFT):
			speed *= fast_move_multiplier
		if Input.is_key_pressed(KEY_CTRL):
			speed *= slow_move_multiplier

		global_position += direction * speed * delta


func handle_rotation(delta: float) -> void:
	var rotation_input := 0.0

	if Input.is_key_pressed(KEY_Q):
		rotation_input -= 1.0
	if Input.is_key_pressed(KEY_E):
		rotation_input += 1.0

	rotation.y += rotation_input * rotation_speed * delta


func handle_zoom(delta: float) -> void:
	var weight := 1.0 - exp(-zoom_smoothing * delta)
	camera.size = lerpf(camera.size, target_zoom, weight)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed

		elif event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_zoom -= zoom_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_zoom += zoom_speed

		target_zoom = clampf(target_zoom, min_zoom, max_zoom)

	elif event is InputEventMouseMotion and dragging:
		var pan := Vector3(
			-event.relative.x,
			0.0,
			event.relative.y
		)

		pan = global_transform.basis * pan

		global_position += pan * target_zoom * pan_sensitivity
