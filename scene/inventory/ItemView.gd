extends Control
class_name ItemView

# INVENTORY / EQUIPMENT UI – ARCHITECTURAL RULES
# 1. Un ItemView deve essere sempre figlio del nodo UI che rappresenta,
#    lo slot logico in cui l’item si trova (InventoryGrid o EquipmentSlot).
# 2. Un ItemView non deve mai essere riparentato durante il drag.
#    Il drag è solo un movimento visivo temporaneo.
# 3. Un ItemView non deve mai essere distrutto durante il gameplay.
#    Viene creato una sola volta e poi solo riparentato.
# 4. SOLO PlayerScreen è autorizzato a riparentare gli ItemView.
#    Nessun altro script deve chiamare reparent() sugli ItemView.

var item: InventoryItemData
var equipment_panel: EquipmentPanel
var tooltip: ItemTooltip

signal animation_finished(view: ItemView)

var dragging := false
var returning := false

var drag_offset := Vector2.ZERO
var original_position := Vector2.ZERO
var target_position := Vector2.ZERO
var can_equip_validator: Callable
var can_unequip_validator: Callable
var is_inventory_open: Callable

@onready var visual := $Visual
@onready var invalid_overlay := $InvalidOverlay
@onready var label := $Label

const DRAG_LERP := 18.0
const RETURN_LERP := 14.0
var last_mouse_pos := Vector2.ZERO
var drag_velocity := Vector2.ZERO
var grab_offset_local := Vector2.ZERO

const MAX_ROTATION := 0.25
const ROTATION_LERP := 14.0
const MIN_DRAG_SPEED := 30.0
const TOOLTIP_PADDING := 28

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	pivot_offset = Vector2.ZERO

	mouse_filter = Control.MOUSE_FILTER_PASS
	visual.mouse_filter = Control.MOUSE_FILTER_STOP
	visual.gui_input.connect(_on_gui_input)
	visual.mouse_entered.connect(_on_mouse_entered)
	visual.mouse_exited.connect(_on_mouse_exited)

	target_position = global_position
	
func bind(
	_item: InventoryItemData,
	_panel: EquipmentPanel,
	_can_equip: Callable,
	_can_unequip: Callable,
	_is_inventory_open: Callable
) -> void:
	item = _item
	equipment_panel = _panel
	can_equip_validator = _can_equip
	can_unequip_validator = _can_unequip
	is_inventory_open = _is_inventory_open

	size = Vector2(
		60 * item.equipment.size.x + 4 * (item.equipment.size.x - 1),
		60 * item.equipment.size.y + 4 * (item.equipment.size.y - 1)
	)

	visual.size = size
	invalid_overlay.size = size
	label.text = item.equipment.display_name

func _process(delta: float) -> void:
	if dragging:
		target_position = get_global_mouse_position() - drag_offset
		global_position = global_position.lerp(target_position, DRAG_LERP * delta)
		_update_drag_rotation(delta)

	elif returning:
		global_position = global_position.lerp(target_position, RETURN_LERP * delta)

		visual.rotation = lerp(visual.rotation, 0.0, ROTATION_LERP * delta)
		label.rotation = lerp(label.rotation, 0.0, ROTATION_LERP * delta)
		invalid_overlay.rotation = lerp(invalid_overlay.rotation, 0.0, ROTATION_LERP * delta)

		if global_position.distance_to(target_position) < 0.5:
			global_position = target_position
			returning = false
			visual.rotation = 0.0
			label.rotation = 0.0
			invalid_overlay.rotation = 0.0
			animation_finished.emit(self)

func _on_mouse_entered() -> void:
	if dragging or returning:
		return
	if tooltip:
		return

	tooltip = preload("res://scene/inventory/item_tooltip.tscn").instantiate()
	get_tree().current_scene.add_child(tooltip)
	tooltip.bind(item.equipment)

	await get_tree().process_frame
	_position_tooltip()

func _on_mouse_exited() -> void:
	_close_tooltip()

func _close_tooltip() -> void:
	if tooltip:
		tooltip.queue_free()
		tooltip = null

func _position_tooltip() -> void:
	if not tooltip:
		return

	tooltip.global_position = Vector2(
		global_position.x - tooltip.size.x - TOOLTIP_PADDING,
		global_position.y
	)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_end_drag()
			
func _unhandled_input(event: InputEvent) -> void:
	if not dragging:
		return

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and not event.pressed:
		_end_drag()
		
func _start_drag() -> void:
	if is_inventory_open.is_valid() and not is_inventory_open.call():
		return

	_close_tooltip()
	original_position = global_position
	dragging = true
	_update_z_index()

	equipment_panel.show_valid_drop_slots(item)

	var mouse_pos := get_global_mouse_position()
	drag_offset = mouse_pos - global_position
	grab_offset_local = (mouse_pos - global_position) - visual.size * 0.5

	last_mouse_pos = mouse_pos
	drag_velocity = Vector2.ZERO

func _end_drag() -> void:
	if not dragging:
		return

	dragging = false
	_update_z_index()

	equipment_panel.clear_drop_slot_highlights()

	var slot := equipment_panel.get_slot_under_mouse()
	if slot:
		if item.location == InventoryItemData.ItemLocation.EQUIPPED \
		and slot.slot_id == item.equipped_slot:
			_start_return()
			return

		if can_equip_validator.is_valid() and can_equip_validator.call(item, slot):
			Events.request_equip_item.emit(item, slot)
		else:
			_start_return()
		return

	var cell := equipment_panel.grid.get_best_drop_cell(self)

	if cell == InventoryGrid.INVALID_CELL:
		_start_return()
		return

	if item.location == InventoryItemData.ItemLocation.INVENTORY:
		var other := equipment_panel.grid.get_item_at_cell(cell, item)
		if other != null and other.equipment.size != item.equipment.size:
			_start_return()
			return

	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		if not can_unequip_validator.call(item, cell):
			_start_return()
			return

	Events.request_move_item.emit(item, cell)

func _start_return() -> void:
	returning = true
	_update_z_index()
	target_position = original_position

func start_swap_animation(target_pos: Vector2) -> void:
	dragging = false
	returning = true
	_update_z_index()
	target_position = target_pos

func _update_drag_rotation(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	drag_velocity = (mouse_pos - last_mouse_pos) / max(delta, 0.0001)
	last_mouse_pos = mouse_pos

	var speed := drag_velocity.length()
	if speed < MIN_DRAG_SPEED:
		visual.rotation = lerp(visual.rotation, 0.0, ROTATION_LERP * delta)
		label.rotation = lerp(label.rotation, 0.0, ROTATION_LERP * delta)
		invalid_overlay.rotation = lerp(invalid_overlay.rotation, 0.0, ROTATION_LERP * delta)
		return

	# -----------------------------
	# LEVA (distanza dal centro)
	# -----------------------------
	var half_size = visual.size * 0.5

	var lever_x = clamp(grab_offset_local.x / half_size.x, -1.0, 1.0)
	var lever_y = clamp(grab_offset_local.y / half_size.y, -1.0, 1.0)

	var lever_strength = max(abs(lever_x), abs(lever_y))
	if lever_strength < 0.15:
		visual.rotation = lerp(visual.rotation, 0.0, ROTATION_LERP * delta)
		invalid_overlay.rotation = lerp(invalid_overlay.rotation, 0.0, ROTATION_LERP * delta)
		label.rotation = lerp(label.rotation, 0.0, ROTATION_LERP * delta)
		return

	# -----------------------------
	# DIREZIONE (perpendicolare al movimento)
	# -----------------------------
	var movement := drag_velocity.normalized()

	var torque = (movement.y * lever_x) - (movement.x * lever_y)

	var speed_factor = clamp(speed / 300.0, 0.0, 1.0)
	var target_rotation = clamp(
		torque * MAX_ROTATION * lever_strength * speed_factor,
		-MAX_ROTATION,
		MAX_ROTATION
	)

	visual.rotation = lerp(
		visual.rotation,
		target_rotation,
		ROTATION_LERP * delta
	)
	invalid_overlay.rotation = lerp(
		invalid_overlay.rotation,
		target_rotation,
		ROTATION_LERP * delta
	)
	label.rotation = lerp(
		label.rotation,
		target_rotation,
		ROTATION_LERP * delta
	)

func _update_z_index() -> void:
	if dragging:
		z_index = 2000
	elif returning:
		z_index = 1000
	else:
		match item.location:
			InventoryItemData.ItemLocation.INVENTORY:
				z_index = 10
			InventoryItemData.ItemLocation.EQUIPPED:
				z_index = 200
			_:
				z_index = 0
