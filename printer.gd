extends Node3D

@export_category("Production")
@export var cash_scene: PackedScene = preload("res://Scenes/cash.tscn")
@export var print_interval: float = 1.5

@export_category("Shop")
## Matches a ShopItem id in the catalog, e.g. printer_basic.
## Leave empty for a printer that is always on.
@export var purchase_id: StringName = &"BasePrinter"
@export var hide_when_locked := true

@onready var output_point: Marker3D = $OutputPoint
@onready var print_timer: Timer = $PrintTimer

func _ready() -> void:
	print_timer.wait_time = print_interval
	print_timer.timeout.connect(_produce_cash)

	PurchaseManager.purchased.connect(_on_purchased)
	PurchaseManager.reset_done.connect(_update_running)
	_update_running()


func is_unlocked() -> bool:
	return purchase_id == &"" or PurchaseManager.is_owned(purchase_id)


## Starts or stops the timer depending on ownership.
func _update_running() -> void:
	var unlocked := is_unlocked()

	if hide_when_locked:
		visible = unlocked
		_set_collisions_enabled(unlocked)

	if unlocked:
		if print_timer.is_stopped():
			print_timer.start()
	else:
		print_timer.stop()
		
func _set_collisions_enabled(enabled: bool) -> void:
	for shape in find_children("*", "CollisionShape3D", true, false):
		shape.set_deferred("disabled", not enabled)


func _on_purchased(id: StringName) -> void:
	if id == purchase_id:
		_update_running()


func _produce_cash() -> void:
	if cash_scene == null or not is_unlocked():
		return

	var cash := cash_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(cash)
	cash.global_transform = output_point.global_transform


## Handy for a click-to-buy prompt or a shop button.
func try_buy() -> bool:
	return purchase_id != &"" and PurchaseManager.buy(purchase_id)


func get_price() -> int:
	return PurchaseManager.get_price(purchase_id)
