extends Control
class_name ItemView

signal animation_finished(view: ItemView)
signal drop_requested(view: ItemView, global_pos: Vector2)

var item: InventoryItemData
var tooltip: ItemTooltip

var dragging := false
var returning := false

var drag_offset := Vector2.ZERO
var original_position := Vector2.ZERO
var target_position := Vector2.ZERO

@onready var visual := $Visual
@onready var invalid_overlay := $InvalidOverlay
@onready var label := $Label

const DRAG_LERP := 18.0
const RETURN_LERP := 14.0
const TOOLTIP_PADDING := 28

var last_mouse_pos := Vector2.ZERO
var drag_velocity := Vector2.ZERO
var grab_offset_local := Vector2.ZERO

const MAX_ROTATION := 0.25
const ROTATION_LERP := 14.0
const MIN_DRAG_SPEED := 30.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	pivot_offset = Vector2.ZERO

	mouse_filter = Control.MOUSE_FILTER_PASS
	visual.mouse_filter = Control.MOUSE_FILTER_STOP
	visual.gui_input.connect(_on_gui_input)
	visual.mouse_entered.connect(_on_mouse_entered)
	visual.mouse_exited.connect(_on_mouse_exited)

	_sync_base_position(global_position)


func bind(_item: InventoryItemData) -> void:
	item = _item

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
		_reset_rotation(delta)

		if global_position.distance_to(target_position) < 0.5:
			global_position = target_position
			returning = false
			_reset_rotation_immediate()
			animation_finished.emit(self)
			_update_z_index()


# ----------------------------------------------------
# INPUT
# ----------------------------------------------------

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_end_drag()


func _unhandled_input(event: InputEvent) -> void:
	if dragging \
	and event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and not event.pressed:
		_end_drag()


func _start_drag() -> void:
	_close_tooltip()
	_sync_base_position(global_position)
	dragging = true
	_update_z_index()

	var mouse_pos := get_global_mouse_position()
	drag_offset = mouse_pos - global_position
	grab_offset_local = (mouse_pos - global_position) - visual.size * 0.5

	last_mouse_pos = mouse_pos
	drag_velocity = Vector2.ZERO


func _end_drag() -> void:
	if not dragging:
		return

	dragging = false
	drop_requested.emit(self, get_global_mouse_position())


func start_return() -> void:
	dragging = false
	returning = true
	target_position = original_position
	_update_z_index()


# ----------------------------------------------------
# POSITION SYNC (USATA DAL CONTROLLER)
# ----------------------------------------------------

func force_sync_position(pos: Vector2) -> void:
	_sync_base_position(pos)
	global_position = pos


func _sync_base_position(pos: Vector2) -> void:
	original_position = pos
	target_position = pos


# ----------------------------------------------------
# TOOLTIP
# ----------------------------------------------------

func _on_mouse_entered() -> void:
	if dragging or returning or tooltip:
		return

	tooltip = preload("res://scene/item_management/item/item_tooltip.tscn").instantiate()
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
	if tooltip:
		tooltip.global_position = Vector2(
			global_position.x - tooltip.size.x - TOOLTIP_PADDING,
			global_position.y
		)


# ----------------------------------------------------
# ROTATION
# ----------------------------------------------------

func _update_drag_rotation(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	drag_velocity = (mouse_pos - last_mouse_pos) / max(delta, 0.0001)
	last_mouse_pos = mouse_pos

	var speed := drag_velocity.length()
	if speed < MIN_DRAG_SPEED:
		_reset_rotation(delta)
		return

	var half_size = visual.size * 0.5
	var lever_x = clamp(grab_offset_local.x / half_size.x, -1.0, 1.0)
	var lever_y = clamp(grab_offset_local.y / half_size.y, -1.0, 1.0)

	var lever_strength = max(abs(lever_x), abs(lever_y))
	if lever_strength < 0.15:
		return

	var movement := drag_velocity.normalized()
	var torque = (movement.y * lever_x) - (movement.x * lever_y)

	var speed_factor = clamp(speed / 300.0, 0.0, 1.0)
	var target_rotation = clamp(
		torque * MAX_ROTATION * lever_strength * speed_factor,
		-MAX_ROTATION,
		MAX_ROTATION
	)

	visual.rotation = lerp(visual.rotation, target_rotation, ROTATION_LERP * delta)
	label.rotation = visual.rotation
	invalid_overlay.rotation = visual.rotation


func _reset_rotation(delta: float) -> void:
	visual.rotation = lerp(visual.rotation, 0.0, ROTATION_LERP * delta)
	label.rotation = lerp(label.rotation, 0.0, ROTATION_LERP * delta)
	invalid_overlay.rotation = lerp(invalid_overlay.rotation, 0.0, ROTATION_LERP * delta)


func _reset_rotation_immediate() -> void:
	visual.rotation = 0.0
	label.rotation = 0.0
	invalid_overlay.rotation = 0.0


# ----------------------------------------------------
# Z INDEX
# ----------------------------------------------------

func _update_z_index() -> void:
	if dragging:
		z_index = 2000
	elif returning:
		z_index = 1500
	elif item != null and item.location == InventoryItemData.ItemLocation.EQUIPPED:
		z_index = 1000
	else:
		z_index = 100
