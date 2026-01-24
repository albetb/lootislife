extends Resource
class_name EquipmentData

enum SlotType {
	HAND,
	ARMOR,
	RELIC,
	CONSUMABLE,
	NONE
}

@export var id: String
@export var display_name: String
@export var slot_type: SlotType

@export var description: String
@export var rarity: int = 1

@export var card_templates: Array[CardTemplate] = []

@export var size: Vector2i = Vector2i.ZERO

@export var icon: Texture2D
