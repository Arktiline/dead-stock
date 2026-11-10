extends Node

signal money_changed(amount: int)
signal purchased(id: StringName)
signal purchase_failed(id: StringName, reason: String)
signal reset_done

const CATALOG_PATH := "res://data/shop_catalog.tres"

@export var starting_money := 100

var money := 0
var catalog := {}  # id -> ShopItem
var _owned := {}   # id -> true


func _ready() -> void:
	var cat := load(CATALOG_PATH) as ShopCatalog
	if cat:
		for item in cat.items:
			catalog[item.id] = item
	else:
		push_warning("PurchaseManager: no catalog at %s" % CATALOG_PATH)
	reset()


## Start a fresh game: starting money plus everything marked owned_at_start.
func reset() -> void:
	money = starting_money
	_owned.clear()
	for id in catalog:
		if catalog[id].owned_at_start:
			_owned[id] = true
	money_changed.emit(money)
	reset_done.emit()


func is_owned(id: StringName) -> bool:
	return _owned.has(id)


func owned_ids() -> Array:
	return _owned.keys()


func items_in(category: ShopItem.Category) -> Array[ShopItem]:
	var out: Array[ShopItem] = []
	for id in catalog:
		if catalog[id].category == category:
			out.append(catalog[id])
	return out


func get_price(id: StringName) -> int:
	return catalog[id].price if catalog.has(id) else 0


func requirements_met(id: StringName) -> bool:
	if not catalog.has(id):
		return false
	for req in catalog[id].requires:
		if not is_owned(req):
			return false
	return true


func can_buy(id: StringName) -> bool:
	return catalog.has(id) and not is_owned(id) \
		and requirements_met(id) and money >= get_price(id)


func buy(id: StringName) -> bool:
	if not catalog.has(id):
		purchase_failed.emit(id, "Unknown item")
		return false
	if is_owned(id):
		purchase_failed.emit(id, "Already owned")
		return false
	if not requirements_met(id):
		purchase_failed.emit(id, "Requirements not met")
		return false
	if money < get_price(id):
		purchase_failed.emit(id, "Not enough money")
		return false

	money -= get_price(id)
	_owned[id] = true
	money_changed.emit(money)
	purchased.emit(id)
	return true


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true


# --- debug helpers ---
func unlock_all() -> void:
	for id in catalog:
		if not _owned.has(id):
			_owned[id] = true
			purchased.emit(id)


# --- saving ---
func to_dict() -> Dictionary:
	return {"money": money, "owned": _owned.keys()}


func from_dict(data: Dictionary) -> void:
	money = data.get("money", starting_money)
	_owned.clear()
	for id in data.get("owned", []):
		_owned[StringName(id)] = true
	money_changed.emit(money)
	reset_done.emit()
