extends VBoxContainer
class_name EquipmentPanel

@export var player: Player

var inventory_state: InventoryState
@onready var grid: InventoryGrid

@onready var right_hand_slot: EquipmentSlot = $VBoxContainer/HBoxContainer/RightHandSlot
@onready var left_hand_slot: EquipmentSlot = $VBoxContainer/HBoxContainer/LeftHandSlot
@onready var armor_slot: EquipmentSlot = $VBoxContainer/HBoxContainer2/ArmorSlot
@onready var relic_slots: Array[EquipmentSlot] = [
	$VBoxContainer/HBoxContainer2/RelicContainer/RelicSlot1,
	$VBoxContainer/HBoxContainer2/RelicContainer/RelicSlot2,
]

@onready var consumable_slots: Array[EquipmentSlot] = [
	$ConsumablesContainer/ConsumableSlot1,
	$ConsumablesContainer/ConsumableSlot2,
	$ConsumablesContainer/ConsumableSlot3,
	$ConsumablesContainer/ConsumableSlot4,
]

func _get_slot_for_item(item: InventoryItemData) -> EquipmentSlot:
	return get_slot_by_id(item.equipped_slot)

func get_slot_by_id(slot_id: InventoryItemData.EquippedSlot) -> EquipmentSlot:
	match slot_id:
		InventoryItemData.EquippedSlot.HAND_LEFT:
			return left_hand_slot
		InventoryItemData.EquippedSlot.HAND_RIGHT:
			return right_hand_slot
		InventoryItemData.EquippedSlot.ARMOR:
			return armor_slot
		InventoryItemData.EquippedSlot.RELIC_0:
			return relic_slots[0]
		InventoryItemData.EquippedSlot.RELIC_1:
			return relic_slots[1]
		InventoryItemData.EquippedSlot.CONSUMABLE_0:
			return consumable_slots[0]
		InventoryItemData.EquippedSlot.CONSUMABLE_1:
			return consumable_slots[1]
		InventoryItemData.EquippedSlot.CONSUMABLE_2:
			return consumable_slots[2]
		InventoryItemData.EquippedSlot.CONSUMABLE_3:
			return consumable_slots[3]
		_:
			return null

func get_item_in_slot(slot: EquipmentSlot) -> InventoryItemData:
	if inventory_state == null:
		return null

	for item in inventory_state.inventory.items:
		if item.location != InventoryItemData.ItemLocation.EQUIPPED:
			continue

		if item.equipped_slot == slot.slot_id:
			return item

	return null

func get_slot_under_mouse(exclude: EquipmentSlot = null) -> EquipmentSlot:
	var mouse_pos := get_viewport().get_mouse_position()

	for slot in _get_all_slots():
		if slot == exclude:
			continue
		if slot.get_global_rect().has_point(mouse_pos):
			return slot

	return null

func _clear_all_slots() -> void:
	for slot in _get_all_slots():
		if slot.current_view:
			slot.current_view.source_equipment_slot = null
			slot.current_view = null

func clear_drop_slot_highlights() -> void:
	for slot in _get_all_slots():
		slot.set_highlight(false)

func show_valid_drop_slots(item: InventoryItemData) -> void:
	for slot in _get_all_slots():
		var can_accept = (
			get_tree()
			.get_first_node_in_group("player_screen")
			.can_equip_item(item, slot)
		)
		slot.set_highlight(can_accept)
		
func _get_all_slots() -> Array:
	return [
		right_hand_slot,
		left_hand_slot,
		armor_slot
	] + relic_slots + consumable_slots
	
# -------------------------------------------------
# ITEM CONTAINER INTERFACE
# -------------------------------------------------

func get_grid() -> InventoryGrid:
	return null

func get_state() -> GridState:
	return null

func allows_equip() -> bool:
	return false

func allows_drop_to_inventory() -> bool:
	return true
