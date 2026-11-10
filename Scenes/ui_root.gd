extends Control

@onready var money_label: Label = $TopBar/HBox/MoneyLabel
@onready var shop_button: Button = $TopBar/HBox/ShopButton
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var toast: Label = $Toast

var _toast_tween: Tween


func _ready() -> void:
	toast.hide()
	shop_button.pressed.connect(toggle_shop)

	PurchaseManager.money_changed.connect(_on_money_changed)
	PurchaseManager.purchase_failed.connect(_on_purchase_failed)
	PurchaseManager.purchased.connect(_on_purchased)
	_on_money_changed(PurchaseManager.money)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_shop"):
		toggle_shop()
		get_viewport().set_input_as_handled()


func toggle_shop() -> void:
	shop_panel.visible = not shop_panel.visible


func _on_money_changed(amount: int) -> void:
	money_label.text = "$%d" % amount


func _on_purchased(id: StringName) -> void:
	var item: ShopItem = PurchaseManager.catalog.get(id)
	show_toast("Bought %s" % (item.display_name if item else str(id)))


func _on_purchase_failed(_id: StringName, reason: String) -> void:
	show_toast(reason)


func show_toast(text: String) -> void:
	toast.text = text
	toast.modulate.a = 1.0
	toast.show()
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(toast.hide)
