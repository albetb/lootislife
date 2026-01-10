extends Control
class_name PlayerScreen

@onready var inventory_panel: InventoryPanel = $InventoryPanel
@onready var equipment_panel: EquipmentPanel = $LateralStatsBar/VBoxContainer/EquipmentPanel
@onready var toggle_button: Button = $InventoryToggleButton
@onready var inventory_grid: InventoryGrid = $InventoryPanel/VBoxContainer/InventoryGrid
@onready var sidebar := $LateralStatsBar

var inventory_state := InventoryState.new()
var inventory_open := false

const INVENTORY_LERP := 10.0
const INVENTORY_OFFSET := 8

var inventory_target_pos := Vector2.ZERO
var button_target_pos := Vector2.ZERO

func _ready() -> void:
	add_to_group("player_screen")
	inventory_state.bind_data(
		Player.data.inventory,
		Player.get_inventory_slots()
	)

	inventory_grid.bind(inventory_state, equipment_panel)
	equipment_panel.refresh_from_inventory(
		Player.data.inventory,
		inventory_state,
		inventory_grid
	)

	inventory_panel.visible = true
	_position_inventory(true)
	inventory_panel.global_position = inventory_target_pos
	toggle_button.global_position = button_target_pos

	_update_button()
	toggle_button.pressed.connect(_on_toggle_inventory)

	Events.update_ui.connect(_refresh_ui)
	Events.request_move_item.connect(request_move_item)
	Events.request_equip_item.connect(request_equip_item)
	Events.request_unequip_item.connect(request_unequip_item)

func _process(delta: float) -> void:
	inventory_panel.global_position = inventory_panel.global_position.lerp(
		inventory_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)

	toggle_button.global_position = toggle_button.global_position.lerp(
		button_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)

func _on_toggle_inventory() -> void:
	inventory_open = not inventory_open
	_position_inventory(not inventory_open)
	_update_button()

func _update_button() -> void:
	toggle_button.text = ">" if inventory_open else "<"

func _position_inventory(closed: bool) -> void:
	var sidebar_rect = sidebar.get_global_rect()

	if closed:
		inventory_target_pos = Vector2(
			sidebar_rect.position.x + INVENTORY_OFFSET,
			sidebar_rect.position.y + INVENTORY_OFFSET
		)

		button_target_pos = Vector2(
			sidebar_rect.position.x - toggle_button.size.x - INVENTORY_OFFSET,
			sidebar_rect.position.y + INVENTORY_OFFSET
		)
	else:
		inventory_target_pos = Vector2(
			sidebar_rect.position.x - inventory_panel.size.x - INVENTORY_OFFSET,
			sidebar_rect.position.y + INVENTORY_OFFSET
		)

		button_target_pos = Vector2(
			sidebar_rect.position.x
			- inventory_panel.size.x
			- toggle_button.size.x
			- 2 * INVENTORY_OFFSET,
			sidebar_rect.position.y + INVENTORY_OFFSET
		)

# INVENTORY → INVENTORY
func request_move_item(item: InventoryItemData, target_cell: Vector2i) -> void:
	if not _can_place_item(item, target_cell):
		return

	item.location = InventoryItemData.ItemLocation.INVENTORY
	item.inventory_position = target_cell

	_commit_inventory_change()
	
	print(
	item.equipment.display_name,
	item.location,
	item.inventory_position,
	item.equipped_slot
)

# INVENTORY → EQUIP
func request_equip_item(item: InventoryItemData, slot: EquipmentSlot) -> void:
	var target_slot = slot.slot_id

	if not _can_equip_item(item, target_slot):
		return

	item.location = InventoryItemData.ItemLocation.EQUIPPED
	item.equipped_slot = target_slot

	_commit_inventory_change()

# EQUIP → INVENTORY
func request_unequip_item(item: InventoryItemData, target_cell: Vector2i) -> void:
	if not _can_place_item(item, target_cell):
		return

	item.location = InventoryItemData.ItemLocation.INVENTORY
	item.inventory_position = target_cell
	item.equipped_slot = InventoryItemData.EquippedSlot.NONE

	_commit_inventory_change()
	
	print(
	item.equipment.display_name,
	item.location,
	item.inventory_position,
	item.equipped_slot
)

# VALIDATION
func _can_place_item(item: InventoryItemData, base: Vector2i) -> bool:
	for other in Player.data.inventory.items:
		if other == item:
			continue
		if other.location != InventoryItemData.ItemLocation.INVENTORY:
			continue

		var a_pos := base
		var a_size := item.equipment.size
		var b_pos := other.inventory_position
		var b_size := other.equipment.size

		if _rects_overlap(a_pos, a_size, b_pos, b_size):
			return false

	# bounds
	for dy in range(item.equipment.size.y):
		for dx in range(item.equipment.size.x):
			var cell := base + Vector2i(dx, dy)
			if not inventory_state.is_cell_allowed(cell):
				return false

	return true

func can_equip_item(item: InventoryItemData, slot: EquipmentSlot) -> bool:
	return _can_equip_item(item, slot.slot_id)

func _can_equip_item(item: InventoryItemData, slot: InventoryItemData.EquippedSlot) -> bool:
	# slot già occupato
	for other in Player.data.inventory.items:
		if other.location == InventoryItemData.ItemLocation.EQUIPPED and other.equipped_slot == slot:
			return false

	# tipo compatibile
	match slot:
		InventoryItemData.EquippedSlot.HAND_LEFT:
			return item.equipment.slot_type == EquipmentData.SlotType.HAND
		InventoryItemData.EquippedSlot.HAND_RIGHT:
			return item.equipment.slot_type == EquipmentData.SlotType.HAND

		InventoryItemData.EquippedSlot.ARMOR:
			return item.equipment.slot_type == EquipmentData.SlotType.ARMOR

		InventoryItemData.EquippedSlot.RELIC:
			return item.equipment.slot_type == EquipmentData.SlotType.RELIC

		InventoryItemData.EquippedSlot.CONSUMABLE_0:
			return item.equipment.slot_type == EquipmentData.SlotType.CONSUMABLE
		InventoryItemData.EquippedSlot.CONSUMABLE_1:
			return item.equipment.slot_type == EquipmentData.SlotType.CONSUMABLE
		InventoryItemData.EquippedSlot.CONSUMABLE_2:
			return item.equipment.slot_type == EquipmentData.SlotType.CONSUMABLE
		InventoryItemData.EquippedSlot.CONSUMABLE_3:
			return item.equipment.slot_type == EquipmentData.SlotType.CONSUMABLE

	return false

func _rects_overlap(a_pos: Vector2i, a_size: Vector2i, b_pos: Vector2i, b_size: Vector2i) -> bool:
	return not (
		a_pos.x + a_size.x <= b_pos.x or
		b_pos.x + b_size.x <= a_pos.x or
		a_pos.y + a_size.y <= b_pos.y or
		b_pos.y + b_size.y <= a_pos.y
	)

func _commit_inventory_change() -> void:
	inventory_state.bind_data(
		Player.data.inventory,
		Player.get_inventory_slots()
	)
	Player.save()

func _refresh_ui() -> void:
	inventory_state.bind_data(
		Player.data.inventory,
		Player.get_inventory_slots()
	)

	inventory_grid.bind(inventory_state, equipment_panel)
	equipment_panel.refresh_from_inventory(
		Player.data.inventory,
		inventory_state,
		inventory_grid
	)
	
func is_inventory_open() -> bool:
	return inventory_open
