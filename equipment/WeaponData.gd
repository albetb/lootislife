extends EquipmentData
class_name WeaponData

enum HandUsage {
	ONE_HAND,
	TWO_HAND
}

@export var hand_usage: HandUsage = HandUsage.ONE_HAND
@export var base_damage: int = 0
