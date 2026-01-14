extends RefCounted
class_name InventoryState

const WIDTH := 4
const HEIGHT := 9
const MAX_SLOTS := WIDTH * HEIGHT

var inventory: InventoryData
var allowed_slots: int = MAX_SLOTS

# layout: Vector2i -> InventoryItemData
var layout: Dictionary = {}

func bind_data(data: InventoryData, in_allowed_slots: int) -> void:
	inventory = data
	allowed_slots = in_allowed_slots
	_rebuild_layout()

func _rebuild_layout() -> void:
	layout.clear()

	if inventory == null:
		return

	for item in inventory.items:
		if item.location != InventoryItemData.ItemLocation.INVENTORY:
			continue

		var base := item.inventory_position

		for dy in range(item.equipment.size.y):
			for dx in range(item.equipment.size.x):
				var cell := base + Vector2i(dx, dy)
				layout[cell] = item

func is_cell_allowed(cell: Vector2i) -> bool:
	var index := cell.y * WIDTH + cell.x
	return index < allowed_slots

func get_required_visible_slots() -> int:
	var max_index := allowed_slots - 1

	for cell in layout.keys():
		var index = cell.y * WIDTH + cell.x
		max_index = max(max_index, index)

	return max_index + 1

func get_required_visible_rows() -> int:
	var slots := get_required_visible_slots()
	return int(ceil(float(slots) / float(WIDTH)))

func item_is_out_of_bounds(item: InventoryItemData) -> bool:
	if item.location != InventoryItemData.ItemLocation.INVENTORY:
		return false

	var base := item.inventory_position

	for dy in range(item.equipment.size.y):
		for dx in range(item.equipment.size.x):
			var cell := base + Vector2i(dx, dy)
			if not is_cell_allowed(cell):
				return true

	return false
