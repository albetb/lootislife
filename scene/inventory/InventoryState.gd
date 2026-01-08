# InventoryState.gd
extends RefCounted
class_name InventoryState

const WIDTH := 4
const HEIGHT := 8
const MAX_SLOTS := WIDTH * HEIGHT

var allowed_slots := 20   # dipende da forza/buff

var grid: Array = []
var data: InventoryData
var item_to_entry := {}

# -------------------------------------------------
# SETUP
# -------------------------------------------------

func setup() -> void:
	grid.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		grid[i] = null

func update_allowed_slots(value: int) -> void:
	allowed_slots = value

func bind_data(inventory_data: InventoryData) -> void:
	data = inventory_data
	_rebuild_grid_from_data()
	
func _rebuild_grid_from_data() -> void:
	grid.clear()
	grid.resize(WIDTH * HEIGHT)
	grid.fill(null)
	item_to_entry.clear()

	var entry_to_item := {}
	for entry in data.items:
		var item: ItemInstance

		if entry_to_item.has(entry):
			item = entry_to_item[entry]
		else:
			item = ItemInstance.new()
			item.equipment = entry.equipment
			item.size = entry.size
			entry_to_item[entry] = item

		item.position = entry.position
		item_to_entry[item] = entry

		if entry.equipped_slot == EquipmentData.SlotType.NONE:
			place(item, entry.position.x, entry.position.y)

# -------------------------------------------------
# UTILS
# -------------------------------------------------

func _index(x: int, y: int) -> int:
	return y * WIDTH + x

func is_inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < WIDTH and y < HEIGHT

func is_slot_allowed(x: int, y: int) -> bool:
	return _index(x, y) < allowed_slots
	
func get_required_visible_slots() -> int:
	var max_index := allowed_slots - 1

	var seen := {}
	for cell in grid:
		if cell == null:
			continue
		if seen.has(cell):
			continue
		seen[cell] = true

		var item_end_index = (
			(cell.position.y + cell.size.y - 1) * WIDTH
			+ (cell.position.x + cell.size.x - 1)
		)
		max_index = max(max_index, item_end_index)

	return max_index + 1

# -------------------------------------------------
# PLACEMENT
# -------------------------------------------------

func can_place(item: ItemInstance, x: int, y: int) -> bool:
	for dy in range(item.size.y):
		for dx in range(item.size.x):
			var px := x + dx
			var py := y + dy

			if not is_inside(px, py):
				return false

			# NOTA: NON controlliamo allowed_slots
			if grid[_index(px, py)] != null:
				return false

	return true

func place(item: ItemInstance, x: int, y: int) -> bool:
	if not can_place(item, x, y):
		push_warning("Cannot place item at %s,%s" % [x, y])
		return false

	for dy in range(item.size.y):
		for dx in range(item.size.x):
			grid[_index(x + dx, y + dy)] = item

	item.position = Vector2i(x, y)
	if item_to_entry.has(item):
		item_to_entry[item].position = item.position

	return true

# -------------------------------------------------
# OVERENCUMBERED
# -------------------------------------------------

func item_is_out_of_bounds(item: ItemInstance) -> bool:
	for dy in range(item.size.y):
		for dx in range(item.size.x):
			var p := item.position + Vector2i(dx, dy)
			if not is_slot_allowed(p.x, p.y):
				return true
	return false

func is_overencumbered() -> bool:
	var checked := {}
	for cell in grid:
		if cell == null:
			continue
		if checked.has(cell):
			continue
		checked[cell] = true
		if item_is_out_of_bounds(cell):
			return true
	return false
	
func get_required_visible_rows() -> int:
	# righe minime basate sugli slot consentiti
	var max_row := int(ceil(float(allowed_slots) / float(WIDTH))) - 1

	var seen := {}

	for cell in grid:
		if cell == null:
			continue
		if seen.has(cell):
			continue

		seen[cell] = true

		var bottom_row = cell.position.y + cell.size.y - 1
		max_row = max(max_row, bottom_row)

	return max_row + 1
	
func add_item_from_equipment(item: ItemInstance, target_pos: Vector2i) -> bool:
	if not item_to_entry.has(item):
		push_error("add_item_from_equipment: item senza entry")
		return false

	var entry: InventoryItemData = item_to_entry[item]

	# torna in inventario
	entry.equipped_slot = EquipmentData.SlotType.NONE
	entry.position = target_pos

	return place(item, target_pos.x, target_pos.y)
	
func remove_item(item: ItemInstance) -> void:
	if not item_to_entry.has(item):
		return

	var entry = item_to_entry[item]
	data.items.erase(entry)
	item_to_entry.erase(item)

	for i in range(grid.size()):
		if grid[i] == item:
			grid[i] = null
