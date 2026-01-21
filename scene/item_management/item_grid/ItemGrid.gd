extends Control
class_name ItemGrid

signal grid_resized

@export var slot_scene: PackedScene = preload(
	"res://scene/item_management/item_grid/item_slot.tscn"
)

const SLOT_SIZE := Vector2(64, 64)
const INVALID_CELL := Vector2i(-1, -1)

# Stato DERIVATO (read-only)
var grid_state: GridState = null

# Celle visive della griglia (NON ItemView)
# Vector2i -> GridSlot
var slots: Dictionary = {}

@onready var slots_container: Control = $SlotsContainer
@onready var items_layer: Control = $ItemViewsLayer


# -------------------------------------------------
# BIND
# -------------------------------------------------
# Collega uno stato logico alla griglia.
# La griglia NON osserva cambiamenti di stato:
# viene ricostruita solo quando PlayerScreen lo decide.
func bind(state: GridState) -> void:
	grid_state = state
	_rebuild()


# -------------------------------------------------
# GRID BUILD (SOLO VISIVO)
# -------------------------------------------------
func _rebuild() -> void:
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
		var cell := Vector2i(x, y)

		var slot := slot_scene.instantiate()
		slots_container.add_child(slot)

		slot.position = Vector2(cell) * SLOT_SIZE
		slot.setup(x, y)
		slot.set_out_of_bounds(not grid_state.is_cell_allowed(cell))

		slots[cell] = slot

	custom_minimum_size = Vector2(
		cols * SLOT_SIZE.x,
		grid_state.get_required_visible_rows() * SLOT_SIZE.y
	)

	emit_signal("grid_resized")


# -------------------------------------------------
# DROP / QUERY
# -------------------------------------------------
# Calcola la cella di drop usando la view SOLO come cursore temporaneo.
# NON salva, NON sposta, NON muta stato.
func get_best_drop_cell(view: ItemView) -> Vector2i:
	if grid_state == null:
		return INVALID_CELL

	var local := view.global_position - global_position

	var base_x := int(local.x / SLOT_SIZE.x)
	var base_y := int(local.y / SLOT_SIZE.y)

	if base_x < 0 or base_y < 0:
		return INVALID_CELL

	if local.x - base_x * SLOT_SIZE.x > SLOT_SIZE.x * 0.5:
		base_x += 1
	if local.y - base_y * SLOT_SIZE.y > SLOT_SIZE.y * 0.5:
		base_y += 1

	var cell := Vector2i(base_x, base_y)

	# Validazione completa considerando dimensioni dell'item
	for dy in range(view.item.equipment.size.y):
		for dx in range(view.item.equipment.size.x):
			var c := cell + Vector2i(dx, dy)
			if not slots.has(c):
				return INVALID_CELL
			if not grid_state.is_cell_allowed(c):
				return INVALID_CELL

	return cell


# Ritorna l'item logico che occupa una cella.
# NON usa ItemView.
func get_item_at_cell(
	base_cell: Vector2i,
	exclude: InventoryItemData
) -> InventoryItemData:
	if grid_state == null:
		return null

	for other in grid_state.get_items():
		if other == exclude:
			continue

		if _rects_overlap(
			base_cell,
			exclude.equipment.size,
			other.inventory_position,
			other.equipment.size
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


# Converte una cella logica in posizione globale.
# Usata da ItemMoveController.
func get_snap_global_position(cell: Vector2i) -> Vector2:
	return global_position + Vector2(cell) * SLOT_SIZE
