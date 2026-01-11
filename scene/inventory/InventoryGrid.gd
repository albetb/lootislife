extends Control
class_name InventoryGrid

signal grid_resized

@export var slot_scene: PackedScene = preload("res://scene/inventory/inventory_slot.tscn")
@export var item_view_scene: PackedScene = preload("res://scene/inventory/item_view.tscn")

const SLOT_SIZE := Vector2(64, 64)
const INVALID_CELL := Vector2i(-1, -1)

var inventory_state: InventoryState
var equipment_panel: EquipmentPanel

var slots: Dictionary = {}
var item_views: Dictionary = {} # uid -> ItemView

func bind(state: InventoryState, panel: EquipmentPanel) -> void:
	inventory_state = state
	equipment_panel = panel
	_build_grid()
	_refresh_views()

func _build_grid() -> void:
	for child in get_children():
		child.queue_free()

	slots.clear()

	if inventory_state == null:
		return

	var visible_slots := inventory_state.get_required_visible_slots()
	var cols := inventory_state.WIDTH

	for index in range(visible_slots):
		var x := index % cols
		var y := index / cols

		var slot = slot_scene.instantiate()
		add_child(slot)

		slot.position = Vector2(x, y) * SLOT_SIZE
		slot.setup(x, y)

		var cell := Vector2i(x, y)
		slots[cell] = slot

		slot.set_out_of_bounds(index >= inventory_state.allowed_slots)

	var rows := inventory_state.get_required_visible_rows()
	custom_minimum_size = Vector2(
		cols * SLOT_SIZE.x,
		rows * SLOT_SIZE.y
	)

	emit_signal("grid_resized")

func _refresh_views() -> void:
	if inventory_state == null:
		return

	var alive := {}

	for item in inventory_state.inventory.items:
		alive[item.uid] = item

	for uid in item_views.keys():
		if not alive.has(uid):
			item_views[uid].queue_free()
			item_views.erase(uid)

	for slot in slots.values():
		slot.set_occupied(false)

	for item in inventory_state.inventory.items:
		var view: ItemView

		if not item_views.has(item.uid):
			view = item_view_scene.instantiate()
			add_child(view)

			view.bind(
				item,
				inventory_state,
				self,
				equipment_panel,
				Callable(get_tree().get_first_node_in_group("player_screen"), "can_equip_item"),
				Callable(get_tree().get_first_node_in_group("player_screen"), "is_inventory_open")
			)

			item_views[item.uid] = view
		else:
			view = item_views[item.uid]

		if item.location == InventoryItemData.ItemLocation.INVENTORY:
			if view.get_parent() != self:
				view.reparent(self)

			view.visible = true
			view.position = Vector2(item.inventory_position) * SLOT_SIZE
			view.z_index = 10

			for dy in range(item.equipment.size.y):
				for dx in range(item.equipment.size.x):
					var cell := item.inventory_position + Vector2i(dx, dy)
					if slots.has(cell):
						slots[cell].set_occupied(true)
		else:
			view.visible = false

func get_best_drop_cell(item_view: ItemView) -> Vector2i:
	var local := item_view.global_position - global_position

	var base_x := int(local.x / SLOT_SIZE.x)
	var base_y := int(local.y / SLOT_SIZE.y)

	if base_x < 0 or base_y < 0:
		return INVALID_CELL

	var offset_x := local.x - base_x * SLOT_SIZE.x
	var offset_y := local.y - base_y * SLOT_SIZE.y

	if offset_x > SLOT_SIZE.x * 0.5:
		base_x += 1
	if offset_y > SLOT_SIZE.y * 0.5:
		base_y += 1

	var cell := Vector2i(base_x, base_y)

	for dy in range(item_view.item.equipment.size.y):
		for dx in range(item_view.item.equipment.size.x):
			var c := cell + Vector2i(dx, dy)
			if not slots.has(c):
				return INVALID_CELL
			if not inventory_state.is_cell_allowed(c):
				return INVALID_CELL

	return cell
	
func get_visible_rows() -> int:
	if inventory_state == null:
		return 0
	return inventory_state.get_required_visible_rows()
	
func get_snap_global_position(cell: Vector2i, item: InventoryItemData) -> Vector2:
	var local_pos := Vector2(cell) * SLOT_SIZE
	return global_position + local_pos
