extends GridState
class_name LootGridState

func setup(width: int, height: int) -> void:
	WIDTH = width
	HEIGHT = height
	_rebuild_layout()


func _rebuild_layout() -> void:
	layout.clear()

	var inventory := Player.data.inventory
	if inventory == null:
		return

	for item in inventory.items:
		if item.location != InventoryItemData.ItemLocation.LOOT:
			continue

		var base := item.inventory_position
		for dy in range(item.equipment.size.y):
			for dx in range(item.equipment.size.x):
				layout[base + Vector2i(dx, dy)] = item


func is_cell_allowed(cell: Vector2i) -> bool:
	return (
		cell.x >= 0 and cell.y >= 0 and
		cell.x < WIDTH and cell.y < HEIGHT
	)


func get_required_visible_slots() -> int:
	return get_max_slot()


func get_required_visible_rows() -> int:
	return HEIGHT


func item_is_out_of_bounds(item: InventoryItemData) -> bool:
	if item.location != InventoryItemData.ItemLocation.LOOT:
		return false

	var base := item.inventory_position
	for dy in range(item.equipment.size.y):
		for dx in range(item.equipment.size.x):
			var c := base + Vector2i(dx, dy)
			if not is_cell_allowed(c):
				return true
	return false


func get_items() -> Array:
	var inventory := Player.data.inventory
	if inventory == null:
		return []

	var result: Array = []
	for item in inventory.items:
		if item.location == InventoryItemData.ItemLocation.LOOT:
			result.append(item)
	return result
