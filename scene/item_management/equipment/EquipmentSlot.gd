extends Control
class_name EquipmentSlot

@export var slot_id: InventoryItemData.EquippedSlot

const CELL_SIZE := Vector2(64, 64)
const HIGHLIGHT_COLOR := Color(0.6, 1.0, 0.6, 0.85)

@onready var cells_container: VBoxContainer = $Cells

var _cell_backgrounds: Array[ColorRect] = []
var _default_cell_color: Color


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_cells()


# -------------------------------------------------
# LAYOUT
# -------------------------------------------------
func get_vertical_cells() -> int:
	match slot_id:
		InventoryItemData.EquippedSlot.HAND_LEFT, \
		InventoryItemData.EquippedSlot.HAND_RIGHT, \
		InventoryItemData.EquippedSlot.ARMOR:
			return 2
		_:
			return 1


func _build_cells() -> void:
	for child in cells_container.get_children():
		child.queue_free()

	_cell_backgrounds.clear()
	cells_container.add_theme_constant_override("separation", 0)

	var count := get_vertical_cells()

	for _i in range(count):
		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(60, 60)
		rect.size = rect.custom_minimum_size
		rect.color = Color.ANTIQUE_WHITE
		cells_container.add_child(rect)
		_cell_backgrounds.append(rect)

	_default_cell_color = _cell_backgrounds[0].color

	var slot_size := Vector2(
		CELL_SIZE.x,
		CELL_SIZE.y * count
	)

	custom_minimum_size = slot_size
	size = slot_size


# -------------------------------------------------
# VISUALS
# -------------------------------------------------
func set_highlight(enabled: bool) -> void:
	var color := HIGHLIGHT_COLOR if enabled else _default_cell_color
	for rect in _cell_backgrounds:
		rect.color = color


# -------------------------------------------------
# SNAP
# -------------------------------------------------
func get_snap_global_position(view: ItemView) -> Vector2:
	var rect := get_global_rect()
	return rect.position + (rect.size - view.size) * 0.5
