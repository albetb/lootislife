extends RefCounted
class_name PlayerEquipmentManager

# -------------------------------------------------
# EQUIPMENT SLOTS
# -------------------------------------------------

var left_hand: EquipmentData = null
var right_hand: EquipmentData = null
var armor: EquipmentData = null
var relic: EquipmentData = null

# -------------------------------------------------
# CONSUMABLES
# -------------------------------------------------

const MAX_CONSUMABLES := 4
var consumables: Array[EquipmentData] = []

# -------------------------------------------------
# EQUIP
# -------------------------------------------------

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


# -------------------------------------------------
# DECK GENERATION
# -------------------------------------------------

func generate_deck() -> Array[CardInstance]:
	var deck: Array[CardInstance] = []
	var processed := {} # evita duplicati (two-hand, future slot)

	_add_equipment_cards_unique(left_hand, deck, processed)
	_add_equipment_cards_unique(right_hand, deck, processed)
	_add_equipment_cards_unique(armor, deck, processed)
	_add_equipment_cards_unique(relic, deck, processed)

	for consumable in consumables:
		_add_equipment_cards_unique(consumable, deck, processed)

	return deck


func _add_equipment_cards_unique(
	equipment: EquipmentData,
	deck: Array[CardInstance],
	processed: Dictionary
) -> void:
	if equipment == null:
		return
	if processed.has(equipment):
		return

	processed[equipment] = true
	_add_equipment_cards(equipment, deck)


func _add_equipment_cards(
	equipment: EquipmentData,
	deck: Array[CardInstance]
) -> void:
	for template in equipment.card_templates:
		if not template is CardTemplate:
			continue

		for i in range(template.copies):
			deck.append(_create_card_instance(template, equipment))


# -------------------------------------------------
# CARD FACTORY
# -------------------------------------------------

func _create_card_instance(
		template: CardTemplate,
		source: EquipmentData
	) -> CardInstance:
	var card := CardInstance.new()
	card.setup(template)

	# opzionale ma FUTURE-PROOF
	if card.has_variable("source_equipment"):
		card.source_equipment = source

	return card
