extends Control
class_name EquipmentSlot

const CELL_SIZE := Vector2(64, 64)

@export var slot_id: InventoryItemData.EquippedSlot
@onready var cells_container: VBoxContainer = $Cells

var current_view: ItemView = null

func _ready() -> void:
	cells_container.add_theme_constant_override("separation", 0)
	_build_cells()

func _build_cells() -> void:
	_clear_children(cells_container)

	var count := _get_vertical_cells()

	for i in count:
		var cell := _create_cell()
		cells_container.add_child(cell)

	size = Vector2(CELL_SIZE.x, CELL_SIZE.y * count)
	custom_minimum_size = size
	
func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _get_vertical_cells() -> int:
	match slot_id:
		InventoryItemData.EquippedSlot.HAND_LEFT:
			return 2
		InventoryItemData.EquippedSlot.HAND_RIGHT:
			return 2
		InventoryItemData.EquippedSlot.ARMOR:
			return 2
		_:
			return 1

func _create_cell() -> Control:
	var root := Control.new()
	root.custom_minimum_size = CELL_SIZE
	root.size = CELL_SIZE
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)

	var rect := ColorRect.new()
	rect.color = Color.ANTIQUE_WHITE
	rect.custom_minimum_size = Vector2(60, 60)
	rect.size = Vector2(60, 60)
	rect.position = Vector2(2, 2)

	root.add_child(rect)
	return root

func attach_item_view(view: ItemView) -> void:
	current_view = view
	view.reparent(self)
	view.position = (size - view.size) * 0.5
	view.z_index = 200

func clear() -> void:
	if current_view:
		current_view.source_equipment_slot = null
	current_view = null

func get_snap_global_position(view: ItemView) -> Vector2:
	var rect := get_global_rect()
	var item_rect := view.get_global_rect()
	return rect.position + (rect.size - item_rect.size) * 0.5
