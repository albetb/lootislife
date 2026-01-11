extends Resource
class_name InventoryItemData

@export var uid: String = ""

func ensure_uid() -> void:
	if uid == "":
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		uid = "%d_%d_%d" % [
			Time.get_unix_time_from_system(),
			Time.get_ticks_usec(),
			rng.randi()
		]

@export var equipment: EquipmentData

enum ItemLocation {
	INVENTORY,
	EQUIPPED
}
@export var location := ItemLocation.INVENTORY
@export var inventory_position := Vector2i.ZERO

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
@export var equipped_slot := EquippedSlot.NONE
