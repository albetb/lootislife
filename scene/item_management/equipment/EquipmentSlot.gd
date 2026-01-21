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
	##cells_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	#cells_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#cells_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _get_vertical_cells() -> int:
	match slot_id:
		InventoryItemData.EquippedSlot.HAND_LEFT, InventoryItemData.EquippedSlot.HAND_RIGHT, InventoryItemData.EquippedSlot.ARMOR:
			return 2
		_:
			return 1

func _build_cells() -> void:
	for child in cells_container.get_children():
		child.queue_free()
	_cell_backgrounds.clear()

	var count := _get_vertical_cells()

	cells_container.add_theme_constant_override("separation", 0)

	for i in count:
		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(60, 60)
		rect.size = Vector2(60, 60)
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

func set_highlight(enabled: bool) -> void:
	var color := HIGHLIGHT_COLOR if enabled else _default_cell_color
	for rect in _cell_backgrounds:
		rect.color = color

func get_snap_global_position(view: ItemView) -> Vector2:
	var rect := get_global_rect()
	var height := CELL_SIZE.y * _get_vertical_cells()
	return rect.position + (Vector2(rect.size.x, height) - view.size) * 0.5
