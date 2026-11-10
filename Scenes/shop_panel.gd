extends PanelContainer

const ROW_SCENE := preload("res://UI/shop_item_row.tscn")

@onready var tabs: TabContainer = $Margin/VBox/Tabs
@onready var close_button: Button = $Margin/VBox/Header/CloseButton

@onready var lists := {
	ShopItem.Category.MACHINE: $Margin/VBox/Tabs/Machines/List,
	ShopItem.Category.CONVEYOR: $Margin/VBox/Tabs/Conveyors/List,
	ShopItem.Category.ELEMENT: $Margin/VBox/Tabs/Elements/List,
}

var _rows := {}  # id -> row


func _ready() -> void:
	hide()
	close_button.pressed.connect(hide)

	_build_rows()

	PurchaseManager.purchased.connect(func(_id): refresh_all())
	PurchaseManager.money_changed.connect(func(_amount): refresh_all())
	PurchaseManager.reset_done.connect(refresh_all)


func _build_rows() -> void:
	print("Catalog size: ", PurchaseManager.catalog.size())
	for category in lists:
		print("Category ", category, ": ", PurchaseManager.items_in(category).size(), " items, list node: ", lists[category])
	for category in lists:
		var list: VBoxContainer = lists[category]
		for child in list.get_children():
			child.queue_free()

		var items := PurchaseManager.items_in(category)
		items.sort_custom(func(a, b): return a.price < b.price)

		for item in items:
			var row := ROW_SCENE.instantiate()
			list.add_child(row)
			row.setup(item)
			row.buy_pressed.connect(_on_buy_pressed)
			_rows[item.id] = row

		# Hide tabs with nothing in them.
		var tab_index := list.get_parent().get_index()
		tabs.set_tab_hidden(tab_index, items.is_empty())


func _on_buy_pressed(id: StringName) -> void:
	PurchaseManager.buy(id)


func refresh_all() -> void:
	for row in _rows.values():
		row.refresh()
