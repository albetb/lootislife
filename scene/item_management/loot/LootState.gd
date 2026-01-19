extends GridState
class_name LootState

var items: Array[InventoryItemData] = []

func bind_equipment(equipment_list: Array[EquipmentData]) -> void:
	WIDTH = 4
	HEIGHT = 4
	items.clear()
	layout.clear()

	for eq in equipment_list:
		var item := InventoryItemData.new()
		item.equipment = eq
		item.location = InventoryItemData.ItemLocation.LOOT
		item.ensure_uid()
		items.append(item)

	_place_items_randomly()

func _place_items_randomly() -> void:
	var cells := []
	for y in range(HEIGHT):
		for x in range(WIDTH):
			cells.append(Vector2i(x, y))
	cells.shuffle()

	for item in items:
		for cell in cells:
			if _can_place(item, cell):
				item.inventory_position = cell
				_fill_layout(item, cell)
				break

func _can_place(item: InventoryItemData, base: Vector2i) -> bool:
	for dy in range(item.equipment.size.y):
		for dx in range(item.equipment.size.x):
			var cell := base + Vector2i(dx, dy)
			if cell.x < 0 or cell.y < 0:
				return false
			if cell.x >= WIDTH or cell.y >= HEIGHT:
				return false
			if layout.has(cell):
				return false
	return true

func _fill_layout(item: InventoryItemData, base: Vector2i) -> void:
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
	return false
	
func get_items() -> Array:
	return items

func remove_item(item: InventoryItemData) -> void:
	items.erase(item)
	_rebuild_layout()

func add_item(item: InventoryItemData) -> void:
	items.append(item)
	_rebuild_layout()

func _rebuild_layout() -> void:
	layout.clear()
	for item in items:
		_fill_layout(item, item.inventory_position)
