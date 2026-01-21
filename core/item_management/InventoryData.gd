extends Resource
class_name InventoryData

@export var width: int = 4
@export var height: int = 9

@export var items: Array[InventoryItemData] = []


# -------------------------------------------------
# QUERY
# -------------------------------------------------

func get_item_by_uid(uid: String) -> InventoryItemData:
	for item in items:
		if item.uid == uid:
			return item
	return null


func get_items_by_location(location: InventoryItemData.ItemLocation) -> Array:
	var result: Array = []
	for item in items:
		if item.location == location:
			result.append(item)
	return result


func get_equipped_item(slot: InventoryItemData.EquippedSlot) -> InventoryItemData:
	for item in items:
		if item.location == InventoryItemData.ItemLocation.EQUIPPED \
		and item.equipped_slot == slot:
			return item
	return null


# -------------------------------------------------
# MUTATION (UNICA FONTE DI VERITÀ)
# -------------------------------------------------

func move_item_to_grid(
	uid: String,
	location: InventoryItemData.ItemLocation,
	cell: Vector2i
) -> bool:
	if location != InventoryItemData.ItemLocation.INVENTORY \
	and location != InventoryItemData.ItemLocation.LOOT:
		return false

	var item := get_item_by_uid(uid)
	if item == null:
		return false

	item.location = location
	item.inventory_position = cell
	item.equipped_slot = InventoryItemData.EquippedSlot.NONE
	return true


func move_item_to_equip(
	uid: String,
	slot: InventoryItemData.EquippedSlot
) -> bool:
	var item := get_item_by_uid(uid)
	if item == null:
		return false

	# non deve MAI esserci più di un item per slot
	var existing := get_equipped_item(slot)
	if existing != null:
		return false

	item.location = InventoryItemData.ItemLocation.EQUIPPED
	item.equipped_slot = slot
	item.inventory_position = Vector2i(-1, -1)
	return true


func unequip_item_to_grid(
	uid: String,
	cell: Vector2i
) -> bool:
	var item := get_item_by_uid(uid)
	if item == null:
		return false

	item.location = InventoryItemData.ItemLocation.INVENTORY
	item.inventory_position = cell
	item.equipped_slot = InventoryItemData.EquippedSlot.NONE
	return true


func swap_items(uid_a: String, uid_b: String) -> bool:
	var a := get_item_by_uid(uid_a)
	var b := get_item_by_uid(uid_b)

	if a == null or b == null:
		return false

	# snapshot completo
	var loc_a := a.location
	var loc_b := b.location
	var pos_a := a.inventory_position
	var pos_b := b.inventory_position
	var slot_a := a.equipped_slot
	var slot_b := b.equipped_slot

	# swap atomico
	a.location = loc_b
	b.location = loc_a

	a.inventory_position = pos_b
	b.inventory_position = pos_a

	a.equipped_slot = slot_b
	b.equipped_slot = slot_a

	return true
