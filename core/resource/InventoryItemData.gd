extends Resource
class_name InventoryItemData

@export var equipment: EquipmentData

enum ItemLocation {
	INVENTORY,
	EQUIPPED
}

@export var location: ItemLocation = ItemLocation.INVENTORY

@export var inventory_position: Vector2i = Vector2i.ZERO

enum EquippedSlot {
	NONE,
	HAND_LEFT,
	HAND_RIGHT,
	ARMOR,
	RELIC,
	CONSUMABLE_0,
	CONSUMABLE_1,
	CONSUMABLE_2,
	CONSUMABLE_3
}

@export var equipped_slot: EquippedSlot = EquippedSlot.NONE
