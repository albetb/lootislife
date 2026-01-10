extends Control
class_name ItemView

var item: InventoryItemData
var inventory_state: InventoryState
var grid: InventoryGrid
var equipment_panel: EquipmentPanel
var tooltip: ItemTooltip

var source_equipment_slot: EquipmentSlot = null

var dragging := false
var returning := false

var drag_offset := Vector2.ZERO
var original_position := Vector2.ZERO
var target_position := Vector2.ZERO
var _snap_callback: Callable = Callable()
var can_equip_validator: Callable
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
const TOOLTIP_PADDING := 4

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	pivot_offset = Vector2.ZERO

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.mouse_filter = Control.MOUSE_FILTER_STOP
	visual.gui_input.connect(_on_gui_input)
	visual.mouse_entered.connect(_on_mouse_entered)
	visual.mouse_exited.connect(_on_mouse_exited)

	target_position = global_position

func bind(
		_item: InventoryItemData,
		_state: InventoryState,
		_grid: InventoryGrid,
		_panel: EquipmentPanel,
		_can_equip: Callable,
		_is_inventory_open: Callable
	) -> void:
	item = _item
	inventory_state = _state
	grid = _grid
	equipment_panel = _panel
	can_equip_validator = _can_equip
	is_inventory_open = _is_inventory_open

	# size dal dato reale
	size = Vector2(
		60 * item.equipment.size.x + 4 * (item.equipment.size.x - 1),
		60 * item.equipment.size.y + 4 * (item.equipment.size.y - 1)
	)

	visual.size = size
	invalid_overlay.size = size
	label.text = item.equipment.display_name

	invalid_overlay.visible = inventory_state.item_is_out_of_bounds(item)
	target_position = global_position

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

		if global_position.distance_to(target_position) < 1.0:
			global_position = target_position
			returning = false

			if _snap_callback.is_valid():
				_snap_callback.call()
				_snap_callback = Callable()

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
	print("START DRAG ", item.equipment.display_name)
	dragging = true
	returning = false
	z_index = 2000
	
	var mouse_pos := get_global_mouse_position()
	drag_offset = mouse_pos - global_position

	# offset locale rispetto al centro visuale
	grab_offset_local = (mouse_pos - global_position) - visual.size * 0.5

	last_mouse_pos = mouse_pos
	drag_velocity = Vector2.ZERO

	source_equipment_slot = null
	if get_parent() is EquipmentSlot:
		source_equipment_slot = get_parent() as EquipmentSlot

	original_position = global_position
	target_position = global_position
	
func _end_drag() -> void:
	if not dragging:
		return
	if is_inventory_open.is_valid() and not is_inventory_open.call():
		returning = true
		target_position = original_position
		return

	dragging = false
	z_index = 1000

	var slot := equipment_panel.get_slot_under_mouse()
	if slot and can_equip_validator.is_valid():
		if can_equip_validator.call(item, slot):
			var snap_pos := slot.get_snap_global_position(self)
			_start_snap_to(snap_pos, func():
				Events.request_equip_item.emit(item, slot)
				_finalize_reparent()
			)
			return

	var cell := grid.get_best_drop_cell(self)
	if cell != InventoryGrid.INVALID_CELL:
		var snap_pos := grid.get_snap_global_position(cell, item)

		if item.location == InventoryItemData.ItemLocation.EQUIPPED:
			_start_snap_to(snap_pos, func():
				Events.request_unequip_item.emit(item, cell)
				_finalize_reparent()
			)
		else:
			_start_snap_to(snap_pos, func():
				Events.request_move_item.emit(item, cell)
				_finalize_reparent()
			)
		return

	returning = true
	target_position = original_position

	_snap_callback = func():
		if source_equipment_slot:
			source_equipment_slot.attach_item_view(self)

func _start_snap_to(pos: Vector2, on_complete: Callable) -> void:
	dragging = false
	returning = true
	target_position = pos
	_snap_callback = on_complete
	
func _finalize_reparent() -> void:
	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		grid.unregister_view(self)

		var slot := equipment_panel._get_slot_for_item(item)
		if slot:
			slot.attach_item_view(self)
			z_index = 200
	else:
		var gp := global_position
		reparent(grid)
		global_position = gp
		grid.register_view(self)
		z_index = 10
		
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
