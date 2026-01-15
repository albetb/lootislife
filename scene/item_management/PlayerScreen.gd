extends Control
class_name PlayerScreen

# INVENTORY / EQUIPMENT UI – ARCHITECTURAL RULES
# 1. Un ItemView deve essere sempre figlio del nodo UI che rappresenta,
#    lo slot logico in cui l’item si trova (InventoryGrid o EquipmentSlot).
# 2. Un ItemView non deve mai essere riparentato durante il drag.
#    Il drag è solo un movimento visivo temporaneo.
# 3. Un ItemView non deve mai essere distrutto durante il gameplay.
#    Viene creato una sola volta e poi solo riparentato.
# 4. SOLO PlayerScreen è autorizzato a riparentare gli ItemView.
#    Nessun altro script deve chiamare reparent() sugli ItemView.

@onready var inventory_panel: InventoryPanel = $InventoryPanel
@onready var equipment_panel: EquipmentPanel = $LateralStatsBar/VBoxContainer/EquipmentPanel
@onready var toggle_button: Button = $InventoryToggleButton
@onready var inventory_grid: InventoryGrid = $InventoryPanel/VBoxContainer/InventoryGrid
@onready var sidebar := $LateralStatsBar

var inventory_state := InventoryState.new()
var inventory_open := false

const INVENTORY_LERP := 10.0
const INVENTORY_OFFSET := 8

var active_swap: SwapTransaction = null

var inventory_target_pos := Vector2.ZERO
var button_target_pos := Vector2.ZERO

func _ready() -> void:
	add_to_group("player_screen")
	inventory_state.bind_data(
		Player.data.inventory,
		Player.get_inventory_slots()
	)

	inventory_grid.bind(inventory_state, equipment_panel)
	inventory_grid._refresh_views()
	sync_item_views()

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
	var bottom_y = sidebar_rect.position.y + sidebar_rect.size.y

	if closed:
		inventory_target_pos = Vector2(
			sidebar_rect.position.x + INVENTORY_OFFSET,
			bottom_y - inventory_panel.size.y - INVENTORY_OFFSET
		)

		button_target_pos = Vector2(
			sidebar_rect.position.x - toggle_button.size.x - INVENTORY_OFFSET,
			bottom_y - toggle_button.size.y - INVENTORY_OFFSET
		)
	else:
		inventory_target_pos = Vector2(
			sidebar_rect.position.x - inventory_panel.size.x - INVENTORY_OFFSET,
			bottom_y - inventory_panel.size.y - INVENTORY_OFFSET
		)

		button_target_pos = Vector2(
			sidebar_rect.position.x
			- inventory_panel.size.x
			- toggle_button.size.x
			- 2 * INVENTORY_OFFSET,
			bottom_y - toggle_button.size.y - INVENTORY_OFFSET
		)

# INVENTORY → INVENTORY
func request_move_item(item: InventoryItemData, target_cell: Vector2i) -> void:
	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		request_unequip_item(item, target_cell)
		return
	
	if not inventory_state.is_cell_allowed(target_cell):
		return

	# swap inventario - inventario
	var other := inventory_grid.get_item_at_cell(target_cell, item)
	if other != null:
		if other.equipment.size != item.equipment.size:
			return

		var view_a = inventory_grid.item_views[item.uid]
		var view_b = inventory_grid.item_views[other.uid]

		var pos_a := _inventory_global_pos(other.inventory_position)
		var pos_b := _inventory_global_pos(item.inventory_position)

		_start_swap_transaction(
			[
				{ "view": view_a, "target": pos_a },
				{ "view": view_b, "target": pos_b }
			],
			func():
				var tmp := other.inventory_position
				other.inventory_position = item.inventory_position
				item.inventory_position = tmp

				item.location = InventoryItemData.ItemLocation.INVENTORY
				other.location = InventoryItemData.ItemLocation.INVENTORY
		)
		return

	if not _can_place_item(item, target_cell):
		return

	item.location = InventoryItemData.ItemLocation.INVENTORY
	item.inventory_position = target_cell

	var view = inventory_grid.item_views[item.uid]
	view.start_swap_animation(_inventory_global_pos(target_cell))

	_commit_inventory_change()

# INVENTORY → EQUIP
func request_equip_item(item: InventoryItemData, slot: EquipmentSlot) -> void:
	var target_slot := slot.slot_id

	# -----------------------------
	# EQUIP → EQUIP
	# -----------------------------
	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		var source_slot := item.equipped_slot
		if source_slot == target_slot:
			return

		if not _can_equip_item(item, target_slot):
			return

		var view = inventory_grid.item_views[item.uid]
		var other := _get_equipped_item_in_slot(target_slot)

		# EQUIP → EQUIP (slot VUOTO)  ✅ FIX
		if other == null:
			var target_pos := slot.get_snap_global_position(view)

			_start_swap_transaction(
				[
					{ "view": view, "target": target_pos }
				],
				func():
					item.equipped_slot = target_slot
			)
			return

		# EQUIP → EQUIP (swap)
		if not _can_equip_item(other, source_slot):
			return

		var other_view = inventory_grid.item_views[other.uid]

		var source_slot_node := equipment_panel.get_slot_by_id(source_slot)
		var target_slot_node := equipment_panel.get_slot_by_id(target_slot)

		var target_a := target_slot_node.get_snap_global_position(view)
		var target_b := source_slot_node.get_snap_global_position(other_view)

		_start_swap_transaction(
			[
				{ "view": view, "target": target_a },
				{ "view": other_view, "target": target_b }
			],
			func():
				item.equipped_slot = target_slot
				other.equipped_slot = source_slot
		)
		return

	# -----------------------------
	# INVENTORY → EQUIP
	# -----------------------------
	if not _can_equip_item(item, target_slot):
		return

	var source_cell := item.inventory_position
	var dragged_view = inventory_grid.item_views[item.uid]
	var other := _get_equipped_item_in_slot(target_slot)

	# INVENTORY → EQUIP (swap)
	if other != null:
		var other_view = inventory_grid.item_views[other.uid]

		var equip_target := slot.get_snap_global_position(dragged_view)
		var inv_target := _inventory_global_pos(source_cell)

		_start_swap_transaction(
			[
				{ "view": dragged_view, "target": equip_target },
				{ "view": other_view, "target": inv_target }
			],
			func():
				other.location = InventoryItemData.ItemLocation.INVENTORY
				other.inventory_position = source_cell
				other.equipped_slot = InventoryItemData.EquippedSlot.NONE

				item.location = InventoryItemData.ItemLocation.EQUIPPED
				item.equipped_slot = target_slot
		)
		return

	# INVENTORY → EQUIP (slot vuoto)
	item.location = InventoryItemData.ItemLocation.EQUIPPED
	item.equipped_slot = target_slot

	dragged_view.start_swap_animation(slot.get_snap_global_position(dragged_view))
	_commit_inventory_change()

# EQUIP → INVENTORY
func request_unequip_item(item: InventoryItemData, target_cell: Vector2i) -> void:
	var equip_view = inventory_grid.item_views[item.uid]
	var source_slot := item.equipped_slot
	var other := inventory_grid.get_item_at_cell(target_cell, item)

	if other != null:
		if other.equipment.size != item.equipment.size:
			return
		if not _can_equip_item(other, source_slot):
			return

		var inv_view = inventory_grid.item_views[other.uid]
		var inv_target := _inventory_global_pos(target_cell)
		var equip_slot = equipment_panel.get_slot_by_id(source_slot)
		var equip_target = equip_slot.get_snap_global_position(inv_view)

		_start_swap_transaction(
			[
				{ "view": equip_view, "target": inv_target },
				{ "view": inv_view, "target": equip_target }
			],
			func():
				item.location = InventoryItemData.ItemLocation.INVENTORY
				item.inventory_position = target_cell
				item.equipped_slot = InventoryItemData.EquippedSlot.NONE

				other.location = InventoryItemData.ItemLocation.EQUIPPED
				other.equipped_slot = source_slot
		)
		return

	if not _can_place_item(item, target_cell):
		return

	item.location = InventoryItemData.ItemLocation.INVENTORY
	item.inventory_position = target_cell
	item.equipped_slot = InventoryItemData.EquippedSlot.NONE

	equip_view.start_swap_animation(_inventory_global_pos(target_cell))
	_commit_inventory_change()

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
	# tipo compatibile
	match slot:
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
	
func can_unequip_item(item: InventoryItemData, target_cell: Vector2i) -> bool:
	var other := inventory_grid.get_item_at_cell(target_cell, item)

	# swap equip ↔ inventory
	if other != null:
		if other.equipment.size != item.equipment.size:
			return false
		if not _can_equip_item(other, item.equipped_slot):
			return false
		return true

	# unequip normale
	return _can_place_item(item, target_cell)

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
	sync_item_views()
	inventory_grid._build_grid()
	inventory_panel.configure_from_grid()

func _refresh_ui() -> void:
	inventory_state.bind_data(
		Player.data.inventory,
		Player.get_inventory_slots()
	)

	inventory_grid.bind(inventory_state, equipment_panel)
	sync_item_views()

func is_inventory_open() -> bool:
	return inventory_open

func sync_item_views() -> void:
	for item in Player.data.inventory.items:
		var view: ItemView = inventory_grid.item_views.get(item.uid)
		if view == null:
			continue

		# NON forzare posizione se sta animando
		var is_animating := view.returning

		if item.location == InventoryItemData.ItemLocation.INVENTORY:
			if view.get_parent() != inventory_grid.items_layer:
				view.reparent(inventory_grid.items_layer)

			view.visible = true
			if not is_animating:
				view.position = Vector2(item.inventory_position) * InventoryGrid.SLOT_SIZE
			view.z_index = 10

		elif item.location == InventoryItemData.ItemLocation.EQUIPPED:
			var slot := equipment_panel._get_slot_for_item(item)
			if slot == null:
				view.visible = false
				continue

			if view.get_parent() != slot:
				view.reparent(slot)

			view.visible = true
			if not is_animating:
				var cell_count := slot._get_vertical_cells()
				var size := Vector2(64, 64 * cell_count)
				view.position = (size - view.size) * 0.5
			view.z_index = 200

class SwapTransaction:
	var views: Array[ItemView] = []
	var completed := {}

	func add(view: ItemView):
		views.append(view)
		completed[view] = false

	func mark_done(view: ItemView) -> bool:
		completed[view] = true
		for v in views:
			if not completed[v]:
				return false
		return true

func _start_swap_transaction(pairs: Array, commit_func: Callable) -> void:
	active_swap = SwapTransaction.new()
	active_swap.set_meta("commit", commit_func)

	for p in pairs:
		var view: ItemView = p.view
		var target: Vector2 = p.target

		active_swap.add(view)
		view.animation_finished.connect(
			_on_swap_anim_finished.bind(active_swap),
			CONNECT_ONE_SHOT
		)
		view.start_swap_animation(target)

func _on_swap_anim_finished(view: ItemView, tx: SwapTransaction) -> void:
	if tx.mark_done(view):
		for v in tx.views:
			v.returning = false
			v.dragging = false

			# reset visivo definitivo
			v.visual.rotation = 0.0
			v.label.rotation = 0.0
			v.invalid_overlay.rotation = 0.0

		var commit = tx.get_meta("commit")
		commit.call()

		_commit_inventory_change()
		active_swap = null

func _get_equipped_item_in_slot(slot: InventoryItemData.EquippedSlot) -> InventoryItemData:
	for item in Player.data.inventory.items:
		if item.location == InventoryItemData.ItemLocation.EQUIPPED \
		and item.equipped_slot == slot:
			return item
	return null
	
func _inventory_global_pos(cell: Vector2i) -> Vector2:
	return inventory_grid.get_snap_global_position(cell, null)
