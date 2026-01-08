extends VBoxContainer
class_name EquipmentPanel

@export var player: Player = Player
var inventory_state: InventoryState

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

func _ready():
	for slot in [
			right_hand_slot,
			left_hand_slot,
			armor_slot,
			relic_slot
		] + consumable_slots:
		slot.request_equip.connect(_on_request_equip)
		slot.request_unequip.connect(_on_request_unequip)

func can_equip(equipment: EquipmentData, target_slot: EquipmentSlot) -> bool:
	# tipo incompatibile
	if equipment.slot_type != target_slot.slot_type:
		return false

	var build := player.data.build

	match equipment.slot_type:
		EquipmentData.SlotType.HAND:
			return _can_equip_hand(equipment, target_slot, build)

		EquipmentData.SlotType.ARMOR:
			return build.armor == null

		EquipmentData.SlotType.RELIC:
			return build.relic == null

		EquipmentData.SlotType.CONSUMABLE:
			return build.consumables.size() < build.MAX_CONSUMABLES

	return false
	
func _can_equip_hand(
		equipment: EquipmentData,
		target_slot: EquipmentSlot,
		build: PlayerEquipmentManager
	) -> bool:
	# TWO HAND: serve che entrambe siano libere
	if equipment is WeaponData:
		var weapon := equipment as WeaponData
		if weapon.hand_usage == WeaponData.HandUsage.TWO_HAND:
			return build.left_hand == null and build.right_hand == null

	# ONE HAND
	if target_slot == right_hand_slot:
		return build.right_hand == null

	if target_slot == left_hand_slot:
		# qui in futuro puoi permettere scudi / off-hand
		return build.left_hand == null

	return false

func _on_request_equip(item: ItemInstance) -> void:
	var entry = inventory_state.item_to_entry.get(item)
	if entry == null:
		push_error("Item senza entry in inventory_state")
		return

	entry.equipped_slot = item.equipment.slot_type
	player.data.build.equip(item.equipment)

	Events.inventory_changed.emit()
	player.save()

func attach_existing_item(view: ItemView, slot: EquipmentSlot) -> void:
	slot.attach_item_view(view)

func _on_request_unequip(item: ItemInstance) -> void:
	var entry = inventory_state.item_to_entry.get(item)
	if entry == null:
		return

	entry.equipped_slot = EquipmentData.SlotType.NONE
	player.data.build.unequip(item.equipment)

	Events.inventory_changed.emit()
	player.save()
	
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
	
func refresh_from_build(build: PlayerEquipmentManager, _inventory: InventoryState, _grid: InventoryGrid) -> void:
	_clear_all_slots()

	# HANDS
	if build.left_hand:
		_attach_equipment_data(build.left_hand, left_hand_slot, _inventory, _grid)

	if build.right_hand:
		_attach_equipment_data(build.right_hand, right_hand_slot, _inventory, _grid)

	# ARMOR / RELIC
	if build.armor:
		_attach_equipment_data(build.armor, armor_slot, _inventory, _grid)

	if build.relic:
		_attach_equipment_data(build.relic, relic_slot, _inventory, _grid)

	# CONSUMABLES
	for i in range(min(build.consumables.size(), consumable_slots.size())):
		_attach_equipment_data(build.consumables[i], consumable_slots[i], _inventory, _grid)

func _attach_equipment_data(equipment: EquipmentData, slot: EquipmentSlot, _inventory: InventoryState, _grid: InventoryGrid) -> void:
	var item := ItemInstance.new()
	item.equipment = equipment
	item.size = _get_equipment_size(equipment)

	var view: ItemView = preload("res://scene/inventory/item_view.tscn").instantiate()
	slot.add_child(view)

	view.bind(item, _inventory, _grid, self)

	slot.attach_item_view(view)

func _clear_all_slots() -> void:
	for slot in [
		right_hand_slot,
		left_hand_slot,
		armor_slot,
		relic_slot
	] + consumable_slots:
		slot.clear()

func _attach_equipment(equipment: EquipmentData, slot: EquipmentSlot) -> void:
	var item := ItemInstance.new()
	item.equipment = equipment
	item.size = _get_equipment_size(equipment)

	var view := preload("res://scene/inventory/item_view.tscn").instantiate()
	slot.add_child(view)
	view.bind(item, null, null, self)
	slot.attach_item_view(view)
	
func _get_equipment_size(equipment: EquipmentData) -> Vector2i:
	if equipment.size and equipment.size != Vector2i.ZERO:
		return equipment.size

	match equipment.slot_type:
		EquipmentData.SlotType.HAND, EquipmentData.SlotType.ARMOR:
			return Vector2i(1, 2)
		_:
			return Vector2i(1, 1)
