extends VBoxContainer
class_name EquipmentPanel

@export var player: Player

var inventory_state: InventoryState
@onready var grid: InventoryGrid

@onready var right_hand_slot: EquipmentSlot = $VBoxContainer/HBoxContainer/RightHandSlot
@onready var left_hand_slot: EquipmentSlot = $VBoxContainer/HBoxContainer/LeftHandSlot
@onready var armor_slot: EquipmentSlot = $VBoxContainer/HBoxContainer2/ArmorSlot
@onready var relic_slot: EquipmentSlot = $VBoxContainer/HBoxContainer2/RelicSlot

@onready var consumable_slots: Array[EquipmentSlot] = [
	$ConsumablesContainer/ConsumableSlot1,
	$ConsumablesContainer/ConsumableSlot2,
	$ConsumablesContainer/ConsumableSlot3,
	$ConsumablesContainer/ConsumableSlot4,
]

func _get_slot_for_item(item: InventoryItemData) -> EquipmentSlot:
	match item.equipped_slot:
		InventoryItemData.EquippedSlot.HAND_LEFT:
			return left_hand_slot
		InventoryItemData.EquippedSlot.HAND_RIGHT:
			return right_hand_slot
		InventoryItemData.EquippedSlot.ARMOR:
			return armor_slot
		InventoryItemData.EquippedSlot.RELIC:
			return relic_slot
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

func get_slot_under_mouse(exclude: EquipmentSlot = null) -> EquipmentSlot:
	var mouse_pos := get_viewport().get_mouse_position()

	for slot in [
		right_hand_slot,
		left_hand_slot,
		armor_slot,
		relic_slot
	] + consumable_slots:
		if slot == exclude:
			continue
		if slot.get_global_rect().has_point(mouse_pos):
			return slot

	return null

func _clear_all_slots() -> void:
	for slot in [
		right_hand_slot,
		left_hand_slot,
		armor_slot,
		relic_slot
	] + consumable_slots:
		if slot.current_view:
			slot.current_view.source_equipment_slot = null
			slot.current_view = null
