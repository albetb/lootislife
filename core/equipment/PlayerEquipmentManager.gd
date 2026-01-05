extends RefCounted
class_name PlayerEquipmentManager

# --- Slot principali ---
var left_hand: EquipmentData = null
var right_hand: EquipmentData = null
var armor: EquipmentData = null
var relic: EquipmentData = null

# --- Consumabili ---
const MAX_CONSUMABLES := 4
var consumables: Array[EquipmentData] = []

func equip(item: EquipmentData) -> bool:
	match item.slot_type:
		EquipmentData.SlotType.HAND:
			return _equip_hand(item)
		EquipmentData.SlotType.ARMOR:
			armor = item
			return true
		EquipmentData.SlotType.RELIC:
			relic = item
			return true
		EquipmentData.SlotType.CONSUMABLE:
			return _equip_consumable(item)
	return false

func _equip_hand(item: EquipmentData) -> bool:
	if not item is WeaponData:
		return false

	var weapon := item as WeaponData

	if weapon.hand_usage == WeaponData.HandUsage.TWO_HAND:
		left_hand = weapon
		right_hand = weapon
		return true

	# ONE HAND
	if left_hand == null:
		left_hand = weapon
		return true
	elif right_hand == null:
		right_hand = weapon
		return true

	return false

func _equip_consumable(item: EquipmentData) -> bool:
	if consumables.size() >= MAX_CONSUMABLES:
		return false
	consumables.append(item)
	return true

func generate_deck() -> Array[CardInstance]:
	var deck: Array[CardInstance] = []

	_add_equipment_cards(left_hand, deck)
	_add_equipment_cards(right_hand, deck)
	_add_equipment_cards(armor, deck)
	_add_equipment_cards(relic, deck)

	for consumable in consumables:
		_add_equipment_cards(consumable, deck)

	return deck

func _add_equipment_cards(equipment: EquipmentData, deck: Array) -> void:
	if equipment == null:
		return

	for template in equipment.card_templates:
		if not template is CardTemplate:
			continue

		for i in range(template.copies):
			var card := _create_card_instance(template)
			deck.append(card)

func _create_card_instance(template: CardTemplate) -> CardInstance:
	var card := CardInstance.new()
	card.setup(template)
	return card
