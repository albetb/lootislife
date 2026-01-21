extends Control
class_name ItemView

signal animation_finished(view: ItemView)
signal drop_requested(view: ItemView, global_pos: Vector2)

var item: InventoryItemData
var tooltip: ItemTooltip

# -------------------------------------------------
# STATE (READ-ONLY DALL'ESTERNO)
# -------------------------------------------------
var dragging := false
var returning := false

# -------------------------------------------------
# POSITION STATE (PRIVATO)
# -------------------------------------------------
var _anchor_position := Vector2.ZERO
var _target_position := Vector2.ZERO
var _drag_offset := Vector2.ZERO

# -------------------------------------------------
# DRAG DYNAMICS
# -------------------------------------------------
var _last_mouse_pos := Vector2.ZERO
var _drag_velocity := Vector2.ZERO
var _grab_offset_local := Vector2.ZERO

# -------------------------------------------------
# NODES
# -------------------------------------------------
@onready var visual := $Visual
@onready var invalid_overlay := $InvalidOverlay
@onready var label := $Label

# -------------------------------------------------
# CONSTANTS
# -------------------------------------------------
const DRAG_LERP := 18.0
const RETURN_LERP := 14.0

const MAX_ROTATION := 0.25
const ROTATION_LERP := 14.0
const MIN_DRAG_SPEED := 30.0
const TOOLTIP_PADDING := 28


# -------------------------------------------------
# LIFECYCLE
# -------------------------------------------------
func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	pivot_offset = Vector2.ZERO

	mouse_filter = Control.MOUSE_FILTER_PASS
	visual.mouse_filter = Control.MOUSE_FILTER_STOP

	visual.gui_input.connect(_on_gui_input)
	visual.mouse_entered.connect(_on_mouse_entered)
	visual.mouse_exited.connect(_on_mouse_exited)

	_sync_anchor(global_position)


func bind(data: InventoryItemData) -> void:
	item = data

	size = Vector2(
		60 * item.equipment.size.x + 4 * (item.equipment.size.x - 1),
		60 * item.equipment.size.y + 4 * (item.equipment.size.y - 1)
	)

	visual.size = size
	invalid_overlay.size = size
	label.text = item.equipment.display_name


# -------------------------------------------------
# PROCESS (SOLO INTERPOLAZIONE)
# -------------------------------------------------
func _process(delta: float) -> void:
	if dragging:
		_target_position = get_global_mouse_position() - _drag_offset
		global_position = global_position.lerp(_target_position, DRAG_LERP * delta)
		_update_drag_rotation(delta)
		return

	if returning:
		global_position = global_position.lerp(_target_position, RETURN_LERP * delta)
		_reset_rotation(delta)

		if global_position.distance_to(_target_position) < 0.5:
			_finish_return()


# -------------------------------------------------
# PUBLIC MOVEMENT API (USATA DAL CONTROLLER)
# -------------------------------------------------
func move_to(pos: Vector2) -> void:
	_target_position = pos
	returning = true
	_update_z_index()


func force_snap(pos: Vector2) -> void:
	_sync_anchor(pos)
	global_position = pos


func set_anchor_position(pos: Vector2) -> void:
	_sync_anchor(pos)


# -------------------------------------------------
# DRAG INPUT
# -------------------------------------------------
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag()
		else:
			_end_drag()


func _unhandled_input(event: InputEvent) -> void:
	if dragging and event is InputEventMouseButton and not event.pressed:
		_end_drag()


func _begin_drag() -> void:
	_close_tooltip()
	dragging = true
	returning = false

	var mouse_pos := get_global_mouse_position()
	_drag_offset = mouse_pos - global_position
	_grab_offset_local = (mouse_pos - global_position) - visual.size * 0.5

	_last_mouse_pos = mouse_pos
	_drag_velocity = Vector2.ZERO

	_update_z_index()


func _end_drag() -> void:
	if not dragging:
		return

	dragging = false
	drop_requested.emit(self, get_global_mouse_position())


# -------------------------------------------------
# RETURN FINALIZATION
# -------------------------------------------------
func _finish_return() -> void:
	global_position = _target_position
	returning = false
	_reset_rotation_immediate()
	_update_z_index()
	animation_finished.emit(self)


func _sync_anchor(pos: Vector2) -> void:
	_anchor_position = pos
	_target_position = pos


# -------------------------------------------------
# TOOLTIP
# -------------------------------------------------
func _on_mouse_entered() -> void:
	if dragging or returning or tooltip:
		return

	tooltip = preload(
		"res://scene/item_management/item/item_tooltip.tscn"
	).instantiate()

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


# -------------------------------------------------
# ROTATION
# -------------------------------------------------
func _update_drag_rotation(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	_drag_velocity = (mouse_pos - _last_mouse_pos) / max(delta, 0.0001)
	_last_mouse_pos = mouse_pos

	var speed := _drag_velocity.length()
	if speed < MIN_DRAG_SPEED:
		_reset_rotation(delta)
		return

	var half = visual.size * 0.5
	var lever_x = clamp(_grab_offset_local.x / half.x, -1.0, 1.0)
	var lever_y = clamp(_grab_offset_local.y / half.y, -1.0, 1.0)

	var lever_strength = max(abs(lever_x), abs(lever_y))
	if lever_strength < 0.15:
		return

	var movement := _drag_velocity.normalized()
	var torque = (movement.y * lever_x) - (movement.x * lever_y)

	var speed_factor = clamp(speed / 300.0, 0.0, 1.0)
	var target_rot = clamp(
		torque * MAX_ROTATION * lever_strength * speed_factor,
		-MAX_ROTATION,
		MAX_ROTATION
	)

	visual.rotation = lerp(visual.rotation, target_rot, ROTATION_LERP * delta)
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


# -------------------------------------------------
# Z INDEX
# -------------------------------------------------
func _update_z_index() -> void:
	if dragging:
		z_index = 2000
	elif returning:
		z_index = 1500
	elif item != null and item.location == InventoryItemData.ItemLocation.EQUIPPED:
		z_index = 1000
	else:
		z_index = 100
