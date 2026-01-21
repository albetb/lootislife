extends Node
class_name ItemMoveController

var player_screen: PlayerScreen
var inventory_grid: ItemGrid
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
	equipment_panel = ps.equipment_panel
	loot_panel = ps.loot_panel

func sync_initial_equipped_views() -> void:
	for item in Player.data.inventory.items:
		if item.location != InventoryItemData.ItemLocation.EQUIPPED:
			continue

		var view := player_screen.get_item_view(item.uid)
		if view == null:
			continue

		var slot := equipment_panel.get_slot_by_id(item.equipped_slot)
		if slot == null:
			continue

		if view.get_parent() != slot:
			view.reparent(slot)

		view.target_position = slot.get_snap_global_position(view)
		view.returning = true


# -------------------------------------------------
# ENTRY POINT
# -------------------------------------------------
func request_drop(
	item: InventoryItemData,
	view: ItemView,
	target_type: int,
	target_grid: ItemGrid,
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
		view.target_position = p.target

		active_swap.add(view)
		view.animation_finished.connect(
			_on_swap_anim_finished.bind(active_swap),
			CONNECT_ONE_SHOT
		)
		view.returning = true


func _on_swap_anim_finished(view: ItemView, tx: SwapTransaction) -> void:
	if not tx.mark_done(view):
		return

	for v in tx.views:
		v.returning = false
		v.dragging = false
		v.visual.rotation = 0.0
		v.label.rotation = 0.0
		v.invalid_overlay.rotation = 0.0

	tx.commit.call()

	for v in tx.views:
		if is_instance_valid(v):
			_reparent_view(v)
			_set_final_target(v)

	player_screen.sync_item_views()
	active_swap = null


# -------------------------------------------------
# REPOSITION / REPARENT
# -------------------------------------------------
func _set_final_target(view: ItemView) -> void:
	var item := view.item

	match item.location:
		InventoryItemData.ItemLocation.INVENTORY:
			view.target_position = inventory_grid.get_snap_global_position(
				item.inventory_position
			)

		InventoryItemData.ItemLocation.LOOT:
			var grid := loot_panel.get_grid()
			if grid:
				view.target_position = grid.get_snap_global_position(
					item.inventory_position
				)

		InventoryItemData.ItemLocation.EQUIPPED:
			var slot := equipment_panel.get_slot_by_id(item.equipped_slot)
			if slot:
				var h := slot._get_vertical_cells()
				var size := Vector2(64, 64 * h)
				view.target_position = slot.global_position + (size - view.size) * 0.5


func _reparent_view(view: ItemView) -> void:
	var item := view.item

	match item.location:
		InventoryItemData.ItemLocation.INVENTORY:
			if view.get_parent() != inventory_grid.items_layer:
				view.reparent(inventory_grid.items_layer)

		InventoryItemData.ItemLocation.LOOT:
			var grid := loot_panel.get_grid()
			if grid and view.get_parent() != grid.items_layer:
				view.reparent(grid.items_layer)

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
	var inventory := Player.data.inventory
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

	# leggi UNA SOLA VOLTA cosa c’è nello slot
	var other := equipment_panel.get_item_in_slot(slot)

	# -------------------------------------------------
	# SLOT EQUIP VUOTO
	# -------------------------------------------------
	if other == null:
		_start_swap_transaction(
			[
				{ "view": view, "target": slot.get_snap_global_position(view) }
			],
			func():
				inventory.move_item_to_equip(item.uid, target_slot)
		)
		return

	# da qui in poi lo slot è PIENO
	var other_view = player_screen.get_item_view(other.uid)

	# -------------------------------------------------
	# EQUIP ↔ EQUIP (SWAP PURO)
	# -------------------------------------------------
	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		var source_slot := item.equipped_slot
		var source_slot_node := equipment_panel.get_slot_by_id(source_slot)

		_start_swap_transaction(
			[
				{ "view": view, "target": slot.get_snap_global_position(view) },
				{
					"view": other_view,
					"target": source_slot_node.get_snap_global_position(other_view)
				}
			],
			func():
				inventory.swap_items(item.uid, other.uid)
		)
		return

	# -------------------------------------------------
	# INVENTORY / LOOT → EQUIP (CON RITORNO DELL’ALTRO)
	# -------------------------------------------------
	var target_other := _resolve_return_position(other)

	_start_swap_transaction(
		[
			{ "view": view, "target": slot.get_snap_global_position(view) },
			{ "view": other_view, "target": target_other }
		],
		func():
			inventory.move_item_to_equip(item.uid, target_slot)
			inventory.unequip_item_to_grid(
				other.uid,
				player_screen.find_first_free_inventory_cell(other)
			)
	)



# -------------------------------------------------
# GRID
# -------------------------------------------------
func _drop_on_grid(
	item: InventoryItemData,
	view: ItemView,
	grid: ItemGrid,
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
	var inventory := Player.data.inventory
	var other := inventory_grid.get_item_at_cell(cell, item)

	if other == null:
		_start_swap_transaction(
			[{ "view": view, "target": inventory_grid.get_snap_global_position(cell) }],
			func():
				inventory.move_item_to_grid(
					item.uid,
					InventoryItemData.ItemLocation.INVENTORY,
					cell
				)
		)
		return

	if other.equipment.size != item.equipment.size:
		view.start_return()
		return

	var other_view = inventory_grid.item_views[other.uid]

	_start_swap_transaction(
		[
			{ "view": view, "target": inventory_grid.get_snap_global_position(cell) },
			{
				"view": other_view,
				"target": inventory_grid.get_snap_global_position(
					other.inventory_position
				)
			}
		],
		func():
			inventory.swap_items(item.uid, other.uid)
	)


func _drop_on_loot(
	item: InventoryItemData,
	view: ItemView,
	grid: ItemGrid,
	cell: Vector2i
) -> void:
	var inventory := Player.data.inventory
	var other := grid.get_item_at_cell(cell, item)

	if other != null:
		view.start_return()
		return

	_start_swap_transaction(
		[{ "view": view, "target": grid.get_snap_global_position(cell) }],
		func():
			inventory.move_item_to_grid(
				item.uid,
				InventoryItemData.ItemLocation.LOOT,
				cell
			)
	)


# -------------------------------------------------
# UTILS
# -------------------------------------------------
func _resolve_return_position(item: InventoryItemData) -> Vector2:
	match item.location:
		InventoryItemData.ItemLocation.EQUIPPED:
			var slot := equipment_panel.get_slot_by_id(item.equipped_slot)
			return slot.get_snap_global_position(
				inventory_grid.item_views[item.uid]
			)

		InventoryItemData.ItemLocation.LOOT:
			return loot_panel.get_grid().get_snap_global_position(
				item.inventory_position
			)

		_:
			return inventory_grid.get_snap_global_position(
				item.inventory_position
			)
