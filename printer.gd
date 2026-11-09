
extends Node3D

@export_category("Production")
@export var cash_scene: PackedScene = preload("res://Scenes/cash.tscn")
@export var print_interval: float = 1.5

@onready var output_point: Marker3D = $OutputPoint
@onready var print_timer: Timer = $PrintTimer


func _ready() -> void:
	print_timer.wait_time = print_interval
	print_timer.timeout.connect(_produce_cash)
	print_timer.start()


func _produce_cash() -> void:
	if cash_scene == null:
		return

	var cash = cash_scene.instantiate()

	get_tree().current_scene.add_child(cash)
	cash.global_transform = output_point.global_transform
