class_name Inventory
extends Resource

signal inventory_changed

@export var max_size: int = 20
var items: Array[Item] = []

func add_item(item: Item) -> bool:
	if items.size() >= max_size:
		return false
	items.append(item)
	inventory_changed.emit()
	return true

func remove_item(item: Item) -> bool:
	var index = items.find(item)
	if index != -1:
		items.remove_at(index)
		inventory_changed.emit()
		return true
	return false

func has_item(item: Item) -> bool:
	return items.has(item)

func get_items() -> Array[Item]:
	return items.duplicate()
