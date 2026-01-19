extends Node
class_name ItemMoveController

var player_screen: PlayerScreen
var inventory_grid: InventoryGrid
var inventory_state: InventoryState
var equipment_panel: EquipmentPanel
var loot_panel: LootPanel

class SwapTransaction:
	var views: Array[ItemView] = []
	var completed := {}
	var commit: Callable

	func add(view: ItemView) -> void:
		views.append(view)
		completed[view] = false

	func mark_done(view: ItemView) -> bool:
		completed[view] = true
		for v in views:
			if not completed[v]:
				return false
		return true


var active_swap: SwapTransaction = null

func setup(ps: PlayerScreen) -> void:
	player_screen = ps
	inventory_grid = ps.inventory_grid
	inventory_state = ps.inventory_state
	equipment_panel = ps.equipment_panel
	loot_panel = ps.loot_panel

# -------------------------------------------------
# ENTRY POINT
# -------------------------------------------------
func request_drop(
	item: InventoryItemData,
	view: ItemView,
	target_type: int,
	target_grid: InventoryGrid,
	target_slot: EquipmentSlot,
	target_cell: Vector2i
) -> void:

	if active_swap != null:
		view.start_return()
		return

	match target_type:
		PlayerScreen.DropTargetType.EQUIPMENT:
			_drop_on_equipment(item, view, target_slot)

		PlayerScreen.DropTargetType.GRID:
			_drop_on_grid(item, view, target_grid, target_cell)

		_:
			view.start_return()

# -------------------------------------------------
# TRANSACTION CORE
# -------------------------------------------------
func _start_swap_transaction(pairs: Array, commit_func: Callable) -> void:
	active_swap = SwapTransaction.new()
	active_swap.commit = commit_func

	for p in pairs:
		var view: ItemView = p.view
		var target: Vector2 = p.target

		active_swap.add(view)

		view.global_position = view.global_position
		view.target_position = target

		view.animation_finished.connect(
			_on_swap_anim_finished.bind(active_swap),
			CONNECT_ONE_SHOT
		)

		view.returning = true


func _on_swap_anim_finished(view: ItemView, tx: SwapTransaction) -> void:
	if not tx.mark_done(view):
		return

	# reset visivo
	for v in tx.views:
		v.returning = false
		v.dragging = false
		v.visual.rotation = 0.0
		v.label.rotation = 0.0
		v.invalid_overlay.rotation = 0.0

	# commit logico
	tx.commit.call()

	# RIPARENT CORRETTO DOPO IL COMMIT
	for v in tx.views:
		if is_instance_valid(v):
			_reparent_view_to_logical_owner(v)
			_realign_target_after_reparent(v)

	# refresh UI
	player_screen._commit_inventory_change()
	active_swap = null
	
func _realign_target_after_reparent(view: ItemView) -> void:
	var item := view.item

	match item.location:
		InventoryItemData.ItemLocation.INVENTORY:
			view.target_position = inventory_grid.items_layer.global_position + Vector2(item.inventory_position) * InventoryGrid.SLOT_SIZE

		InventoryItemData.ItemLocation.LOOT:
			var loot_grid := loot_panel.get_grid()
			if loot_grid:
				view.target_position = loot_grid.items_layer.global_position + Vector2(item.inventory_position) * InventoryGrid.SLOT_SIZE

		InventoryItemData.ItemLocation.EQUIPPED:
			var slot := equipment_panel.get_slot_by_id(item.equipped_slot)
			if slot:
				var h := slot._get_vertical_cells()
				var size := Vector2(64, 64 * h)
				view.target_position = slot.global_position + (size - view.size) * 0.5

	view.global_position = view.target_position


func _reparent_view_to_logical_owner(view: ItemView) -> void:
	var item := view.item

	match item.location:
		InventoryItemData.ItemLocation.INVENTORY:
			if view.get_parent() != inventory_grid.items_layer:
				view.reparent(inventory_grid.items_layer)

		InventoryItemData.ItemLocation.LOOT:
			var loot_grid := loot_panel.get_grid()
			if loot_grid and view.get_parent() != loot_grid.items_layer:
				view.reparent(loot_grid.items_layer)

		InventoryItemData.ItemLocation.EQUIPPED:
			var slot := equipment_panel.get_slot_by_id(item.equipped_slot)
			if slot and view.get_parent() != slot:
				view.reparent(slot)

# -------------------------------------------------
# EQUIPMENT
# -------------------------------------------------
func _drop_on_equipment(
	item: InventoryItemData,
	view: ItemView,
	slot: EquipmentSlot
) -> void:

	var target_slot := slot.slot_id

	# stesso slot → ritorno
	if item.location == InventoryItemData.ItemLocation.EQUIPPED \
	and item.equipped_slot == target_slot:
		view.start_return()
		return

	# validazione tipo
	if not player_screen.can_equip_item(item, slot):
		view.start_return()
		return

	var other := player_screen._get_equipped_item_in_slot(target_slot)

	# -------------------------------------------------
	# SLOT VUOTO
	# -------------------------------------------------
	if other == null:
		_start_swap_transaction(
			[
				{ "view": view, "target": slot.get_snap_global_position(view) }
			],
			func():
				item.location = InventoryItemData.ItemLocation.EQUIPPED
				item.equipped_slot = target_slot
		)
		return

	# -------------------------------------------------
	# EQUIP ↔ EQUIP (SWAP PURO)
	# -------------------------------------------------
	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		var source_slot := item.equipped_slot
		var other_view = inventory_grid.item_views[other.uid]

		var target_a := slot.get_snap_global_position(view)
		var source_slot_node := equipment_panel.get_slot_by_id(source_slot)
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

	# -------------------------------------------------
	# INVENTORY / LOOT → EQUIP (SWAP)
	# -------------------------------------------------
	var other_view = inventory_grid.item_views[other.uid]
	var target_equip := slot.get_snap_global_position(view)
	var target_other := _resolve_return_position(other)

	_start_swap_transaction(
		[
			{ "view": view, "target": target_equip },
			{ "view": other_view, "target": target_other }
		],
		func():
			# item → equip
			if item.location == InventoryItemData.ItemLocation.LOOT:
				player_screen.loot_state.remove_item(item)
				Player.data.inventory.items.append(item)
			item.location = InventoryItemData.ItemLocation.EQUIPPED
			item.equipped_slot = target_slot

			# other → inventory
			other.location = InventoryItemData.ItemLocation.INVENTORY
			other.equipped_slot = InventoryItemData.EquippedSlot.NONE
			other.inventory_position = player_screen._find_first_free_inventory_cell(other)
	)

func _swap_equipped(
	item: InventoryItemData,
	other: InventoryItemData,
	target_slot
) -> void:

	item.location = InventoryItemData.ItemLocation.EQUIPPED
	item.equipped_slot = target_slot

	other.location = InventoryItemData.ItemLocation.INVENTORY
	other.equipped_slot = InventoryItemData.EquippedSlot.NONE
	other.inventory_position = player_screen._find_first_free_inventory_cell(other)

# -------------------------------------------------
# GRID
# -------------------------------------------------
func _drop_on_grid(
	item: InventoryItemData,
	view: ItemView,
	grid: InventoryGrid,
	cell: Vector2i
) -> void:

	if grid == inventory_grid:
		_drop_on_inventory(item, view, cell)
		return

	if loot_panel.is_open() and grid == loot_panel.get_grid():
		_drop_on_loot(item, view, grid, cell)
		return

	view.start_return()

func _drop_on_inventory(
	item: InventoryItemData,
	view: ItemView,
	cell: Vector2i
) -> void:

	# validazione spazio
	if not player_screen._can_place_in_state(item, cell, inventory_state):
		view.start_return()
		return

	var other := inventory_grid.get_item_at_cell(cell, item)

	# -------------------------------------------------
	# SLOT VUOTO
	# -------------------------------------------------
	if other == null:
		_start_swap_transaction(
			[
				{ "view": view, "target": inventory_grid.get_snap_global_position(cell) }
			],
			func():
				# LOOT → INVENTORY
				if item.location == InventoryItemData.ItemLocation.LOOT:
					player_screen.loot_state.remove_item(item)
					Player.data.inventory.items.append(item)

				item.location = InventoryItemData.ItemLocation.INVENTORY
				item.inventory_position = cell
		)
		return

	# -------------------------------------------------
	# SWAP INVENTORY ↔ INVENTORY
	# -------------------------------------------------
	if other.equipment.size != item.equipment.size:
		view.start_return()
		return

	var other_view = inventory_grid.item_views[other.uid]

	_start_swap_transaction(
		[
			{ "view": view, "target": inventory_grid.get_snap_global_position(cell) },
			{
				"view": other_view,
				"target": inventory_grid.get_snap_global_position(other.inventory_position)
			}
		],
		func():
			# se item arriva dal loot, entra nell’inventory
			if item.location == InventoryItemData.ItemLocation.LOOT:
				player_screen.loot_state.remove_item(item)
				Player.data.inventory.items.append(item)

			other.inventory_position = item.inventory_position
			item.inventory_position = cell

			item.location = InventoryItemData.ItemLocation.INVENTORY
	)

func _drop_on_loot(
	item: InventoryItemData,
	view: ItemView,
	grid: InventoryGrid,
	cell: Vector2i
) -> void:
	var loot_state := player_screen.loot_state

	if not player_screen._can_place_in_state(item, cell, loot_state):
		view.start_return()
		return

	var other := grid.get_item_at_cell(cell, item)

	# -------------------------
	# SLOT VUOTO
	# -------------------------
	if other == null:
		_start_swap_transaction(
			[{ "view": view, "target": grid.get_snap_global_position(cell) }],
			func():
				if item.location == InventoryItemData.ItemLocation.INVENTORY:
					Player.data.inventory.items.erase(item)
					loot_state.add_item(item)

				item.location = InventoryItemData.ItemLocation.LOOT
				item.inventory_position = cell
		)
		return

	view.start_return()

# -------------------------------------------------
# UTILS
# -------------------------------------------------
func _resolve_return_position(item: InventoryItemData) -> Vector2:
	match item.location:
		InventoryItemData.ItemLocation.EQUIPPED:
			var slot := equipment_panel.get_slot_by_id(item.equipped_slot)
			return slot.get_snap_global_position(inventory_grid.item_views[item.uid])

		InventoryItemData.ItemLocation.LOOT:
			var loot_grid := loot_panel.get_grid()
			return loot_grid.get_snap_global_position(item.inventory_position)

		_:
			return inventory_grid.get_snap_global_position(item.inventory_position)
