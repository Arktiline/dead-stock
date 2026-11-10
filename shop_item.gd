class_name ShopItem
extends Resource

enum Category { MACHINE, CONVEYOR, ELEMENT }

@export var id: StringName
@export var display_name := ""
@export var category := Category.MACHINE
@export var price := 100
## Owned from the very start of a new game.
@export var owned_at_start := false
## Ids that must be owned before this can be bought.
@export var requires: Array[StringName] = []
