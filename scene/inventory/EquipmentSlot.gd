extends Control
class_name EquipmentSlot

const CELL_SIZE := Vector2(64, 64)

@export var slot_type: EquipmentData.SlotType
var current_item: ItemInstance = null

@onready var cells_container: VBoxContainer = $Cells

signal request_equip(item: ItemInstance)
signal request_unequip(item: ItemInstance)

func _ready() -> void:
	cells_container.add_theme_constant_override("separation", 0)
	_build_cells()

func can_accept(item: ItemInstance) -> bool:
	if current_item != null:
		return false

	if item.equipment.slot_type != slot_type:
		return false

	if item.size.y > _get_vertical_cells():
		return false

	return true

func _get_vertical_cells() -> int:
	match slot_type:
		EquipmentData.SlotType.HAND, EquipmentData.SlotType.ARMOR:
			return 2
		_:
			return 1
			
func _build_cells() -> void:
	_clear_children(cells_container)

	var count := _get_vertical_cells()

	for i in count:
		var cell = _create_cell()
		cells_container.add_child(cell)

	# dimensione finale coerente
	size = Vector2(CELL_SIZE.x, CELL_SIZE.y * count)
	custom_minimum_size = size
	
func _create_cell() -> Control:
	var root := Control.new()
	root.custom_minimum_size = CELL_SIZE
	root.size = CELL_SIZE
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)

	var rect := ColorRect.new()
	rect.color = Color.ANTIQUE_WHITE
	rect.custom_minimum_size = Vector2(60, 60)
	rect.size = Vector2(60, 60)
	rect.position = Vector2(2, 2) # stesso offset inventario

	root.add_child(rect)
	return root
	
func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
		
func can_drop(item_view: ItemView) -> bool:
	return can_accept(item_view.item)
	
func drop_item(item_view: ItemView) -> bool:
	if not can_accept(item_view.item):
		return false

	current_item = item_view.item
	request_equip.emit(item_view.item)
	return true
	
func clear_item(item: ItemInstance) -> void:
	if current_item == item:
		current_item = null
		
func get_snap_global_position(item_view: ItemView) -> Vector2:
	var rect := get_global_rect()
	var item_rect := item_view.get_global_rect()

	# centra l'item nello slot
	return rect.position + (rect.size - item_rect.size) * 0.5
	
func attach_item_view(view: ItemView) -> void:
	current_item = view.item
	view.source_equipment_slot = self

	view.reparent(self)
	view.global_position = get_snap_global_position(view)
	view.z_index = 0
	
func clear() -> void:
	current_item = null

	for child in get_children():
		if child is ItemView:
			child.source_equipment_slot = null
			child.reparent(get_tree().current_scene) # o un container neutro
