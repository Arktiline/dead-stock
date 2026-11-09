
@tool
extends Node3D

@export_category("Dimensions")
@export_range(1.0, 30.0, 0.5) var length: float = 6.0:
	set(value):
		length = value
		_update_conveyor()

@export_range(0.5, 10.0, 0.1) var width: float = 2.0:
	set(value):
		width = value
		_update_conveyor()

@export_range(0.05, 1.0, 0.05) var belt_thickness: float = 0.2:
	set(value):
		belt_thickness = value
		_update_conveyor()

@export_range(0.1, 3.0, 0.1) var wall_height: float = 0.6:
	set(value):
		wall_height = value
		_update_conveyor()

@export_range(0.05, 0.5, 0.05) var wall_thickness: float = 0.12:
	set(value):
		wall_thickness = value
		_update_conveyor()


@export_category("Materials")
@export var belt_material: Material:
	set(value):
		belt_material = value
		_update_conveyor()

@export var wall_material: Material:
	set(value):
		wall_material = value
		_update_conveyor()


@onready var belt: MeshInstance3D = $Belt
@onready var left_wall: MeshInstance3D = $LeftWall
@onready var right_wall: MeshInstance3D = $RightWall

@onready var belt_collision: CollisionShape3D = $StaticBody3D/BeltCollision
@onready var left_collision: CollisionShape3D = $StaticBody3D/LeftWallCollision
@onready var right_collision: CollisionShape3D = $StaticBody3D/RightWallCollision

var updating := false


func _ready() -> void:
	_update_conveyor()


func _update_conveyor() -> void:
	if updating:
		return

	if not is_inside_tree():
		return

	updating = true

	var wall_x := width / 2.0 - wall_thickness / 2.0
	var wall_y := belt_thickness / 2.0 + wall_height / 2.0

	_set_mesh(belt, Vector3(width, belt_thickness, length),
		Vector3.ZERO, belt_material)

	_set_mesh(left_wall, Vector3(wall_thickness, wall_height, length),
		Vector3(-wall_x, wall_y, 0), wall_material)

	_set_mesh(right_wall, Vector3(wall_thickness, wall_height, length),
		Vector3(wall_x, wall_y, 0), wall_material)

	_set_collision(belt_collision,
		Vector3(width, belt_thickness, length), Vector3.ZERO)

	_set_collision(left_collision,
		Vector3(wall_thickness, wall_height, length),
		Vector3(-wall_x, wall_y, 0))

	_set_collision(right_collision,
		Vector3(wall_thickness, wall_height, length),
		Vector3(wall_x, wall_y, 0))

	updating = false


func _set_mesh(
	mesh_instance: MeshInstance3D,
	dimensions: Vector3,
	local_position: Vector3,
	material: Material
) -> void:
	if not is_instance_valid(mesh_instance):
		return

	var box := BoxMesh.new()
	box.size = dimensions

	mesh_instance.mesh = box
	mesh_instance.position = local_position
	mesh_instance.material_override = material


func _set_collision(
	collision: CollisionShape3D,
	dimensions: Vector3,
	local_position: Vector3
) -> void:
	if not is_instance_valid(collision):
		return

	var shape := BoxShape3D.new()
	shape.size = dimensions

	collision.shape = shape
	collision.position = local_position
