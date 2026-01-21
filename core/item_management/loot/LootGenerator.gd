extends Node
class_name LootGenerator

const LOOT_WIDTH := 4
const LOOT_HEIGHT := 4

static func generate_test_loot() -> void:
	var inventory := Player.data.inventory

	var loot: Array[EquipmentData] = [
		load("res://core/equipment/templates/short_sword.tres"),
		load("res://core/equipment/templates/ninnolo_base.tres")
	]

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for eq in loot:
		var item := InventoryItemData.new()
		item.equipment = eq
		item.ensure_uid()
		item.location = InventoryItemData.ItemLocation.LOOT

		var cell := _find_free_loot_cell(item, inventory)
		if cell == ItemGrid.INVALID_CELL:
			continue

		item.inventory_position = cell
		inventory.items.append(item)


static func _find_free_loot_cell(
	item: InventoryItemData,
	inventory: InventoryData
) -> Vector2i:
	var cells: Array[Vector2i] = []

	for y in range(LOOT_HEIGHT):
		for x in range(LOOT_WIDTH):
			cells.append(Vector2i(x, y))

	cells.shuffle()

	for cell in cells:
		if _can_place_in_loot(cell, item, inventory):
			return cell

	return ItemGrid.INVALID_CELL


static func _can_place_in_loot(
	base: Vector2i,
	item: InventoryItemData,
	inventory: InventoryData
) -> bool:
	# bounds check
	for dy in range(item.equipment.size.y):
		for dx in range(item.equipment.size.x):
			var c := base + Vector2i(dx, dy)
			if c.x < 0 or c.y < 0:
				return false
			if c.x >= LOOT_WIDTH or c.y >= LOOT_HEIGHT:
				return false

	# overlap check
	for other in inventory.items:
		if other.location != InventoryItemData.ItemLocation.LOOT:
			continue

		if _rects_overlap(
			base, item.equipment.size,
			other.inventory_position, other.equipment.size
		):
			return false

	return true


static func _rects_overlap(
	a_pos: Vector2i, a_size: Vector2i,
	b_pos: Vector2i, b_size: Vector2i
) -> bool:
	return not (
		a_pos.x + a_size.x <= b_pos.x or
		b_pos.x + b_size.x <= a_pos.x or
		a_pos.y + a_size.y <= b_pos.y or
		b_pos.y + b_size.y <= a_pos.y
	)
