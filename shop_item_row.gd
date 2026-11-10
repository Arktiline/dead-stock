extends PanelContainer

signal buy_pressed(id: StringName)

@onready var name_label: Label = $HBox/NameLabel
@onready var info_label: Label = $HBox/InfoLabel
@onready var buy_button: Button = $HBox/BuyButton

var item: ShopItem


func setup(p_item: ShopItem) -> void:
	item = p_item
	name_label.text = item.display_name
	buy_button.pressed.connect(func(): buy_pressed.emit(item.id))
	refresh()


func refresh() -> void:
	if PurchaseManager.is_owned(item.id):
		info_label.text = ""
		buy_button.text = "Owned"
		buy_button.disabled = true
	elif not PurchaseManager.requirements_met(item.id):
		info_label.text = "Requires: %s" % ", ".join(_requirement_names())
		buy_button.text = "Locked"
		buy_button.disabled = true
	else:
		info_label.text = "$%d" % item.price
		buy_button.text = "Buy"
		buy_button.disabled = PurchaseManager.money < item.price


func _requirement_names() -> PackedStringArray:
	var names := PackedStringArray()
	for req in item.requires:
		var req_item: ShopItem = PurchaseManager.catalog.get(req)
		names.append(req_item.display_name if req_item else str(req))
	return names
