extends VBoxContainer
class_name EquipmentPanel

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

func get_slot_by_id(slot_id: InventoryItemData.EquippedSlot) -> EquipmentSlot:
	match slot_id:
		InventoryItemData.EquippedSlot.HAND_LEFT: return left_hand_slot
		InventoryItemData.EquippedSlot.HAND_RIGHT: return right_hand_slot
		InventoryItemData.EquippedSlot.ARMOR: return armor_slot
		InventoryItemData.EquippedSlot.RELIC_0: return relic_slots[0]
		InventoryItemData.EquippedSlot.RELIC_1: return relic_slots[1]
		InventoryItemData.EquippedSlot.CONSUMABLE_0: return consumable_slots[0]
		InventoryItemData.EquippedSlot.CONSUMABLE_1: return consumable_slots[1]
		InventoryItemData.EquippedSlot.CONSUMABLE_2: return consumable_slots[2]
		InventoryItemData.EquippedSlot.CONSUMABLE_3: return consumable_slots[3]
		_: return null

func get_slot_under_mouse() -> EquipmentSlot:
	var mouse_pos := get_viewport().get_mouse_position()
	for slot in _get_all_slots():
		if slot.get_global_rect().has_point(mouse_pos):
			return slot
	return null

func show_valid_drop_slots(item: InventoryItemData) -> void:
	for slot in _get_all_slots():
		slot.set_highlight(_slot_accepts(item, slot))

func clear_drop_slot_highlights() -> void:
	for slot in _get_all_slots():
		slot.set_highlight(false)

func can_equip(item: InventoryItemData, slot: EquipmentSlot) -> bool:
	return _slot_accepts(item, slot)
	
func _slot_accepts(item: InventoryItemData, slot: EquipmentSlot) -> bool:
	match slot.slot_id:
		InventoryItemData.EquippedSlot.HAND_LEFT, InventoryItemData.EquippedSlot.HAND_RIGHT:
			return item.equipment.slot_type == EquipmentData.SlotType.HAND

		InventoryItemData.EquippedSlot.ARMOR:
			return item.equipment.slot_type == EquipmentData.SlotType.ARMOR

		InventoryItemData.EquippedSlot.RELIC_0, InventoryItemData.EquippedSlot.RELIC_1:
			return item.equipment.slot_type == EquipmentData.SlotType.RELIC

		InventoryItemData.EquippedSlot.CONSUMABLE_0, InventoryItemData.EquippedSlot.CONSUMABLE_1, InventoryItemData.EquippedSlot.CONSUMABLE_2, InventoryItemData.EquippedSlot.CONSUMABLE_3:
			return item.equipment.slot_type == EquipmentData.SlotType.CONSUMABLE

		_:
			return false

func _get_all_slots() -> Array:
	return [right_hand_slot, left_hand_slot, armor_slot] + relic_slots + consumable_slots
	
func get_item_in_slot(slot: EquipmentSlot) -> InventoryItemData:
	var inventory := Player.data.inventory
	for item in inventory.items:
		if item.location == InventoryItemData.ItemLocation.EQUIPPED \
		and item.equipped_slot == slot.slot_id:
			return item
	return null
