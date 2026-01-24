extends Node
class_name ItemMoveController

var player_screen: PlayerScreen
var inventory_grid: ItemGrid
var equipment_panel: EquipmentPanel
var loot_panel: LootPanel

# -------------------------------------------------
# TRANSACTION
# -------------------------------------------------
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

# -------------------------------------------------
# SETUP
# -------------------------------------------------
func setup(ps: PlayerScreen) -> void:
	player_screen = ps
	inventory_grid = ps.inventory_grid
	equipment_panel = ps.equipment_panel
	loot_panel = ps.loot_panel

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
		_return_view(view)
		return

	match target_type:
		PlayerScreen.DropTargetType.EQUIPMENT:
			_drop_on_equipment(item, view, target_slot)

		PlayerScreen.DropTargetType.GRID:
			_drop_on_grid(item, view, target_grid, target_cell)

		_:
			_return_view(view)

# -------------------------------------------------
# TRANSACTION CORE
# -------------------------------------------------
func _start_swap_transaction(
	views: Array[ItemView],
	commit_func: Callable
) -> void:
	active_swap = SwapTransaction.new()
	active_swap.commit = commit_func

	for view in views:
		active_swap.add(view)

		# FORZA una animazione (anche se è già sopra)
		var start_pos := view.global_position
		view.move_to(start_pos)

		view.animation_finished.connect(
			_on_swap_anim_finished.bind(active_swap),
			CONNECT_ONE_SHOT
		)

func _on_swap_anim_finished(view: ItemView, tx: SwapTransaction) -> void:
	if not tx.mark_done(view):
		return

	# commit logico UNA SOLA VOLTA
	tx.commit.call()

	# animazione finale unica e simultanea
	for v in tx.views:
		if not is_instance_valid(v):
			continue

		v.dragging = false
		v.returning = true
		v.sprite.rotation = 0.0
		v.label.rotation = 0.0

		_reparent_view(v)
		var final_pos := _resolve_final_position(v.item, v)
		v.move_to(final_pos)

	player_screen.sync_item_views()
	active_swap = null

# -------------------------------------------------
# REPARENT / FINAL TARGET
# -------------------------------------------------
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
	if (
		item.location == InventoryItemData.ItemLocation.EQUIPPED
		and item.equipped_slot == target_slot
	):
		_return_view(view)
		return

	# validazione tipo
	if not player_screen.can_equip_item(item, slot):
		_return_view(view)
		return

	# leggi UNA SOLA VOLTA lo slot
	var other := equipment_panel.get_item_in_slot(slot)

	# ---------------------------------------------
	# SLOT VUOTO
	# ---------------------------------------------
	if other == null:
		_start_swap_transaction(
			[view],
			func():
				inventory.move_item_to_equip(item.uid, target_slot)
		)
		return

	var other_view := player_screen.get_item_view(other.uid)
	if other_view == null:
		_return_view(view)
		return

	# ---------------------------------------------
	# EQUIP ↔ EQUIP
	# ---------------------------------------------
	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		var source_slot := equipment_panel.get_slot_by_id(item.equipped_slot)

		_start_swap_transaction(
			[view, other_view],
			func():
				inventory.swap_items(item.uid, other.uid)
		)

		return

	# ---------------------------------------------
	# INVENTORY / LOOT → EQUIP
	# ---------------------------------------------
	var source_slot := equipment_panel.get_slot_by_id(other.equipped_slot)
	if not player_screen.can_equip_item(item, slot):
		_return_view(view)
		return
	if not player_screen.can_equip_item(other, source_slot):
		_return_view(view)
		return

	_start_swap_transaction(
		[view, other_view],
		func():
			inventory.swap_items(item.uid, other.uid)
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

	_return_view(view)

func _drop_on_inventory(
	item: InventoryItemData,
	view: ItemView,
	cell: Vector2i
) -> void:
	var inventory := Player.data.inventory
	var other := inventory_grid.get_item_at_cell(cell, item)

	if other == null:
		_start_swap_transaction(
			[view],
			func():
				inventory.move_item_to_grid(
					item.uid,
					InventoryItemData.ItemLocation.INVENTORY,
					cell
				)
		)
		return

	if other.equipment.size != item.equipment.size:
		_return_view(view)
		return

	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		var source_slot := equipment_panel.get_slot_by_id(item.equipped_slot)
		if not player_screen.can_equip_item(other, source_slot):
			_return_view(view)
			return

	var other_view := player_screen.get_item_view(other.uid)
	if other_view == null:
		_return_view(view)
		return

	_start_swap_transaction(
		[view, other_view],
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

	# ---------------------------------------------
	# CELLA VUOTA
	# ---------------------------------------------
	if other == null:
		_start_swap_transaction(
			[view],
			func():
				inventory.move_item_to_grid(
					item.uid,
					InventoryItemData.ItemLocation.LOOT,
					cell
				)
		)
		return

	# ---------------------------------------------
	# SIZE MISMATCH
	# ---------------------------------------------
	if other.equipment.size != item.equipment.size:
		_return_view(view)
		return

	# ---------------------------------------------
	# VALIDAZIONE EQUIP SE SERVE
	# ---------------------------------------------
	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		var source_slot := equipment_panel.get_slot_by_id(item.equipped_slot)
		if not player_screen.can_equip_item(other, source_slot):
			_return_view(view)
			return

	# ---------------------------------------------
	# SWAP VIEW
	# ---------------------------------------------
	var other_view := player_screen.get_item_view(other.uid)
	if other_view == null:
		_return_view(view)
		return

	_start_swap_transaction(
		[view, other_view],
		func():
			inventory.swap_items(item.uid, other.uid)
	)

# -------------------------------------------------
# UTILS
# -------------------------------------------------
func _resolve_return_position(item: InventoryItemData) -> Vector2:
	var view := player_screen.get_item_view(item.uid)
	if view == null:
		return Vector2.ZERO

	match item.location:
		InventoryItemData.ItemLocation.EQUIPPED:
			var slot := equipment_panel.get_slot_by_id(item.equipped_slot)
			return slot.get_snap_global_position(view)

		InventoryItemData.ItemLocation.LOOT:
			return loot_panel.get_grid().get_snap_global_position(
				item.inventory_position
			)

		_:
			return inventory_grid.get_snap_global_position(
				item.inventory_position
			)

func sync_all_views_immediate() -> void:
	for item in Player.data.inventory.items:
		var view := player_screen.get_item_view(item.uid)
		if view == null:
			continue

		# reparent corretto
		_reparent_view(view)

		# posizione finale corretta
		var pos := _resolve_final_position(item, view)
		view.force_snap(pos)

func _resolve_final_position(
	item: InventoryItemData,
	view: ItemView
) -> Vector2:
	match item.location:
		InventoryItemData.ItemLocation.INVENTORY:
			return inventory_grid.get_snap_global_position(
				item.inventory_position
			)

		InventoryItemData.ItemLocation.LOOT:
			var grid := loot_panel.get_grid()
			if grid:
				return grid.get_snap_global_position(
					item.inventory_position
				)

		InventoryItemData.ItemLocation.EQUIPPED:
			var slot := equipment_panel.get_slot_by_id(item.equipped_slot)
			if slot:
				return slot.get_snap_global_position(view)

	return Vector2.ZERO

func _return_view(view: ItemView) -> void:
	var pos := _resolve_return_position(view.item)
	view.move_to(pos)
