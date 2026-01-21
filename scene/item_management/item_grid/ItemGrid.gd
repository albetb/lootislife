extends Control
class_name ItemGrid

signal grid_resized

@export var slot_scene: PackedScene = preload("res://scene/item_management/item_grid/item_slot.tscn")
@export var item_view_scene: PackedScene = preload("res://scene/item_management/item/item_view.tscn")

const SLOT_SIZE := Vector2(64, 64)
const INVALID_CELL := Vector2i(-1, -1)

var grid_state: GridState

var slots: Dictionary = {}          # Vector2i -> GridSlot
var item_views: Dictionary = {}     # uid -> ItemView

@onready var slots_container: Control = $SlotsContainer
@onready var items_layer: Control = $ItemViewsLayer


# -------------------------------------------------
# BIND
# -------------------------------------------------
func bind(state: GridState) -> void:
	grid_state = state
	_build_grid()
	_refresh_views()
	sync_views()


# -------------------------------------------------
# GRID BUILD
# -------------------------------------------------
func _build_grid() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	slots.clear()

	if grid_state == null:
		return

	var visible_slots := grid_state.get_required_visible_slots()
	var cols := grid_state.WIDTH

	for index in range(visible_slots):
		var x := index % cols
		var y := index / cols

		var slot = slot_scene.instantiate()
		slots_container.add_child(slot)

		slot.position = Vector2(x, y) * SLOT_SIZE
		slot.setup(x, y)

		var cell := Vector2i(x, y)
		slots[cell] = slot

		slot.set_out_of_bounds(not grid_state.is_cell_allowed(cell))

	custom_minimum_size = Vector2(
		cols * SLOT_SIZE.x,
		grid_state.get_required_visible_rows() * SLOT_SIZE.y
	)

	emit_signal("grid_resized")


# -------------------------------------------------
# ITEM VIEWS
# -------------------------------------------------
func _refresh_views() -> void:
	if grid_state == null:
		return

	for item in grid_state.get_items():
		if item_views.has(item.uid):
			continue

		var view: ItemView = item_view_scene.instantiate()
		items_layer.add_child(view)

		view.bind(item)
		item_views[item.uid] = view


func sync_views() -> void:
	if grid_state == null:
		return

	for item in grid_state.get_items():
		var view: ItemView = item_views.get(item.uid)
		if view == null:
			continue

		if view.get_parent() != items_layer:
			view.reparent(items_layer)

		view.visible = true
		view.position = Vector2(item.inventory_position) * SLOT_SIZE
		view.z_index = 10


func clear_all_views() -> void:
	for view in item_views.values():
		view.queue_free()

	item_views.clear()


# -------------------------------------------------
# DROP / QUERY
# -------------------------------------------------
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
			if not grid_state.is_cell_allowed(c):
				return INVALID_CELL

	return cell


func get_item_at_cell(base_cell: Vector2i, exclude: InventoryItemData) -> InventoryItemData:
	for other in grid_state.get_items():
		if other == exclude:
			continue

		if _rects_overlap(
			base_cell, exclude.equipment.size,
			other.inventory_position, other.equipment.size
		):
			return other

	return null


func _rects_overlap(
	a_pos: Vector2i, a_size: Vector2i,
	b_pos: Vector2i, b_size: Vector2i
) -> bool:
	return not (
		a_pos.x + a_size.x <= b_pos.x or
		b_pos.x + b_size.x <= a_pos.x or
		a_pos.y + a_size.y <= b_pos.y or
		b_pos.y + b_size.y <= a_pos.y
	)


# -------------------------------------------------
# UTILS
# -------------------------------------------------
func get_visible_rows() -> int:
	if grid_state == null:
		return 0
	return grid_state.get_required_visible_rows()


func get_snap_global_position(cell: Vector2i) -> Vector2:
	return global_position + Vector2(cell) * SLOT_SIZE
