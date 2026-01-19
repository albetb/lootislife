# INVENTORY / EQUIPMENT UI – ARCHITECTURAL RULES
# 1. Un ItemView deve essere sempre figlio del nodo UI che rappresenta,
#    lo slot logico in cui l’item si trova (InventoryGrid o EquipmentSlot).
# 2. Un ItemView non deve mai essere riparentato durante il drag.
#    Il drag è solo un movimento visivo temporaneo.
# 3. Le ItemView in inventario e equip non si distruggono mai durante il gameplay.
#    Vengono create una sola volta e poi solo riparentate.
#    Le ItemView in loot devono essere distrutte quando viene chiuso il loot.
# 4. SOLO ItemMoveController è autorizzato a riparentare gli ItemView.
#    Nessun altro script deve chiamare reparent() sugli ItemView.

extends Control
class_name PlayerScreen

@onready var inventory_panel: InventoryPanel = $InventoryPanel
var loot_state: LootState = null
@onready var loot_panel: LootPanel = $LootPanel
@onready var equipment_panel: EquipmentPanel = $LateralStatsBar/VBoxContainer/EquipmentPanel
@onready var toggle_button: Button = $InventoryToggleButton
@onready var inventory_grid: InventoryGrid = $InventoryPanel/VBoxContainer/InventoryGrid
@onready var sidebar := $LateralStatsBar
@onready var blur_panel := $BlurPanel

@onready var move_controller := ItemMoveController.new()

var inventory_state := InventoryState.new()
var inventory_open := false
var loot_open := false

const INVENTORY_LERP := 10.0
const INVENTORY_OFFSET := 8

var inventory_target_pos := Vector2.ZERO
var loot_target_pos := Vector2.ZERO
var button_target_pos := Vector2.ZERO

func _ready() -> void:
	add_to_group("player_screen")

	inventory_state.bind_data(
		Player.data.inventory,
		Player.get_inventory_slots()
	)

	inventory_grid.bind(inventory_state)
	inventory_grid._refresh_views()
	sync_item_views()

	add_child(move_controller)
	move_controller.setup(self)

	inventory_panel.visible = true
	_update_panels_position()

	inventory_panel.global_position = inventory_target_pos
	loot_panel.global_position = loot_target_pos
	toggle_button.global_position = button_target_pos

	toggle_button.pressed.connect(_on_toggle_inventory)
	inventory_panel.inventory_panel_resized.connect(_update_panels_position)
	loot_panel.loot_panel_resized.connect(_update_panels_position)
	loot_panel.loot_panel_closed.connect(_on_loot_panel_closed)

	Events.update_ui.connect(_refresh_ui)
	Events.treasure_loot_requested.connect(_open_loot_panel)


func _process(delta: float) -> void:
	inventory_panel.global_position = inventory_panel.global_position.lerp(
		inventory_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)

	loot_panel.global_position = loot_panel.global_position.lerp(
		loot_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)

	toggle_button.global_position = toggle_button.global_position.lerp(
		button_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)

# -------------------------------------------------
# PANEL POSITIONING
# -------------------------------------------------
func _on_toggle_inventory() -> void:
	inventory_open = not inventory_open
	_update_panels_position()
	_update_button()

func _update_button() -> void:
	toggle_button.text = ">" if inventory_open else "<"

func _update_panels_position() -> void:
	var sidebar_rect = sidebar.get_global_rect()
	var bottom_y = sidebar_rect.position.y + sidebar_rect.size.y

	if inventory_open:
		inventory_target_pos = Vector2(
			sidebar_rect.position.x - inventory_panel.size.x - INVENTORY_OFFSET,
			bottom_y - inventory_panel.size.y - INVENTORY_OFFSET
		)
		button_target_pos = Vector2(
			inventory_target_pos.x - toggle_button.size.x - INVENTORY_OFFSET,
			bottom_y - toggle_button.size.y - INVENTORY_OFFSET
		)
	else:
		inventory_target_pos = Vector2(
			sidebar_rect.position.x + INVENTORY_OFFSET,
			bottom_y - inventory_panel.size.y - INVENTORY_OFFSET
		)
		button_target_pos = Vector2(
			sidebar_rect.position.x - toggle_button.size.x - INVENTORY_OFFSET,
			bottom_y - toggle_button.size.y - INVENTORY_OFFSET
		)

	if loot_open:
		loot_target_pos = Vector2(
			inventory_target_pos.x - loot_panel.size.x - INVENTORY_OFFSET,
			bottom_y - loot_panel.size.y - INVENTORY_OFFSET
		)
	else:
		loot_target_pos = Vector2(
			sidebar_rect.position.x + INVENTORY_OFFSET,
			bottom_y - loot_panel.size.y - INVENTORY_OFFSET
		)

# -------------------------------------------------
# INVENTORY / UI SYNC
# -------------------------------------------------
func _refresh_ui() -> void:
	inventory_state.bind_data(
		Player.data.inventory,
		Player.get_inventory_slots()
	)
	inventory_grid.bind(inventory_state)
	sync_item_views()

func sync_item_views() -> void:
	_sync_state_items(inventory_state)
	if loot_state != null:
		_sync_state_items(loot_state)
		
func _sync_state_items(state: GridState) -> void:
	for item in state.get_items():
		var view: ItemView = inventory_grid.item_views.get(item.uid)
		if view == null:
			continue

		_register_item_view(view)

		if view.dragging or view.returning:
			continue

		var animating := view.returning

		match item.location:
			InventoryItemData.ItemLocation.INVENTORY:
				if view.get_parent() != inventory_grid.items_layer:
					view.reparent(inventory_grid.items_layer)
				view.visible = true
				if not animating:
					view.position = Vector2(item.inventory_position) * InventoryGrid.SLOT_SIZE

			InventoryItemData.ItemLocation.LOOT:
				var loot_grid := loot_panel.get_grid()
				if loot_grid == null:
					view.visible = false
					continue
				if view.get_parent() != loot_grid.items_layer:
					view.reparent(loot_grid.items_layer)
				view.visible = true
				if not animating:
					view.position = Vector2(item.inventory_position) * InventoryGrid.SLOT_SIZE

			InventoryItemData.ItemLocation.EQUIPPED:
				var slot := equipment_panel._get_slot_for_item(item)
				if slot == null:
					view.visible = false
					continue
				if view.get_parent() != slot:
					view.reparent(slot)
				view.visible = true
				if not animating:
					var h := slot._get_vertical_cells()
					var current_size := Vector2(64, 64 * h)
					view.position = (current_size - view.size) * 0.5


# -------------------------------------------------
# DROP ENTRY POINT
# -------------------------------------------------
func _register_item_view(view: ItemView) -> void:
	if not view.drop_requested.is_connected(_on_item_drop_requested):
		view.drop_requested.connect(_on_item_drop_requested)

func _on_item_drop_requested(view: ItemView, _global_pos: Vector2) -> void:
	var target := _resolve_drop_target(view)

	move_controller.request_drop(
		view.item,
		view,
		target.type,
		target.grid,
		target.slot,
		target.cell
	)

# -------------------------------------------------
# DROP TARGET RESOLUTION
# -------------------------------------------------
enum DropTargetType { NONE, EQUIPMENT, GRID }

class DropTarget:
	var type := DropTargetType.NONE
	var grid: InventoryGrid
	var slot: EquipmentSlot
	var cell := InventoryGrid.INVALID_CELL

func _resolve_drop_target(view: ItemView) -> DropTarget:
	var t := DropTarget.new()

	var slot := equipment_panel.get_slot_under_mouse()
	if slot:
		t.type = DropTargetType.EQUIPMENT
		t.slot = slot
		return t

	if loot_open:
		var loot_grid := loot_panel.get_grid()
		var cell := loot_grid.get_best_drop_cell(view)
		if cell != InventoryGrid.INVALID_CELL:
			t.type = DropTargetType.GRID
			t.grid = loot_grid
			t.cell = cell
			return t

	var inv_cell := inventory_grid.get_best_drop_cell(view)
	if inv_cell != InventoryGrid.INVALID_CELL:
		t.type = DropTargetType.GRID
		t.grid = inventory_grid
		t.cell = inv_cell
		return t

	return t

# -------------------------------------------------
# API USATA DAL MOVE CONTROLLER
# -------------------------------------------------
func can_equip_item(item: InventoryItemData, slot: EquipmentSlot) -> bool:
	match slot.slot_id:
		InventoryItemData.EquippedSlot.HAND_LEFT:
			return item.equipment.slot_type == EquipmentData.SlotType.HAND
		InventoryItemData.EquippedSlot.HAND_RIGHT:
			return item.equipment.slot_type == EquipmentData.SlotType.HAND
		InventoryItemData.EquippedSlot.ARMOR:
			return item.equipment.slot_type == EquipmentData.SlotType.ARMOR
		InventoryItemData.EquippedSlot.RELIC_0:
			return item.equipment.slot_type == EquipmentData.SlotType.RELIC
		InventoryItemData.EquippedSlot.RELIC_1:
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

func _get_equipped_item_in_slot(slot_id) -> InventoryItemData:
	for item in Player.data.inventory.items:
		if item.location == InventoryItemData.ItemLocation.EQUIPPED \
		and item.equipped_slot == slot_id:
			return item
	return null

func _can_place_in_state(
	item: InventoryItemData,
	base: Vector2i,
	state: GridState
) -> bool:
	for other in state.get_items():
		if other == item:
			continue
		if _rects_overlap(
			base, item.equipment.size,
			other.inventory_position, other.equipment.size
		):
			return false

	for dy in range(item.equipment.size.y):
		for dx in range(item.equipment.size.x):
			if not state.is_cell_allowed(base + Vector2i(dx, dy)):
				return false
	return true

func _rects_overlap(a_pos, a_size, b_pos, b_size) -> bool:
	return not (
		a_pos.x + a_size.x <= b_pos.x or
		b_pos.x + b_size.x <= a_pos.x or
		a_pos.y + a_size.y <= b_pos.y or
		b_pos.y + b_size.y <= a_pos.y
	)

func _find_first_free_inventory_cell(item: InventoryItemData) -> Vector2i:
	var cols := inventory_state.WIDTH
	var rows := inventory_state.get_required_visible_rows()

	for y in range(rows):
		for x in range(cols):
			var cell := Vector2i(x, y)

			if not inventory_state.is_cell_allowed(cell):
				continue

			if _can_place_in_state(item, cell, inventory_state):
				return cell

	return InventoryGrid.INVALID_CELL


# -------------------------------------------------
# COMMIT INVENTORY (USATO DAL MOVE CONTROLLER)
# -------------------------------------------------
func _commit_inventory_change() -> void:
	for item in Player.data.inventory.items:
		assert(item.location != null)
	
	inventory_state.bind_data(
		Player.data.inventory,
		Player.get_inventory_slots()
	)

	Player.save()

	inventory_grid.bind(inventory_state)
	inventory_grid._build_grid()
	inventory_panel.configure_from_grid()

	sync_item_views()

# -------------------------------------------------
# LOOT
# -------------------------------------------------
func _open_loot_panel(equipment: Array[EquipmentData]) -> void:
	if loot_panel.is_open():
		loot_panel.close()

	loot_state = LootState.new()
	loot_state.bind_equipment(equipment)

	loot_panel.open(loot_state)
	loot_open = true

	blur_panel.visible = true
	toggle_button.visible = false

	if not inventory_open:
		inventory_open = true

	_update_button()
	_update_panels_position()

func _on_loot_panel_closed() -> void:
	if inventory_open:
		inventory_open = false
		
	loot_state = null
	loot_open = false
	blur_panel.visible = false
	toggle_button.visible = true
	_update_panels_position()
