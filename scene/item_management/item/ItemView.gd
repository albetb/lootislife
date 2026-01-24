extends Control
class_name ItemView

signal animation_finished(view: ItemView)
signal drop_requested(view: ItemView, global_pos: Vector2)
signal drag_started(view: ItemView)
signal drag_ended(view: ItemView)

var item: InventoryItemData
var tooltip: ItemTooltip

var dragging := false
var returning := false
var drag_locked := true

var _target_position := Vector2.ZERO
var _drag_offset := Vector2.ZERO

var _last_mouse_pos := Vector2.ZERO
var _drag_velocity := Vector2.ZERO
var _grab_offset_local := Vector2.ZERO

@onready var sprite: TextureRect = $Sprite
@onready var label: Label = $Label

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
	sprite.mouse_filter = Control.MOUSE_FILTER_STOP

	sprite.gui_input.connect(_on_gui_input)
	sprite.mouse_entered.connect(_on_mouse_entered)
	sprite.mouse_exited.connect(_on_mouse_exited)

	Events.inventory_opened.connect(_on_inventory_opened)
	Events.inventory_closed.connect(_on_inventory_closed)

# -------------------------------------------------
# BIND
# -------------------------------------------------
func bind(data: InventoryItemData) -> void:
	item = data

	size = Vector2(
		60 * item.equipment.size.x + 4 * (item.equipment.size.x - 1),
		60 * item.equipment.size.y + 4 * (item.equipment.size.y - 1)
	)

	sprite.size = size
	sprite.texture = item.equipment.icon
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	label.text = item.equipment.display_name
	
	if item.location != InventoryItemData.ItemLocation.EQUIPPED:
		drag_locked = false

# -------------------------------------------------
# PROCESS
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
# DRAG
# -------------------------------------------------
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag()
		else:
			_end_drag()

func _begin_drag() -> void:
	if drag_locked:
		return

	_close_tooltip()
	dragging = true
	returning = false
	drag_started.emit(self)

	var mouse_pos := get_global_mouse_position()
	_drag_offset = mouse_pos - global_position
	_grab_offset_local = (mouse_pos - global_position) - sprite.size * 0.5

	_last_mouse_pos = mouse_pos
	_drag_velocity = Vector2.ZERO
	_update_z_index()

func _end_drag() -> void:
	if not dragging:
		return

	dragging = false
	drag_ended.emit(self)
	drop_requested.emit(self, get_global_mouse_position())
	
func move_to(pos: Vector2) -> void:
	_target_position = pos
	returning = true
	dragging = false
	_update_z_index()


# -------------------------------------------------
# INVENTORY LOCK
# -------------------------------------------------
func _on_inventory_opened() -> void:
	drag_locked = false

func _on_inventory_closed() -> void:
	if item.location == InventoryItemData.ItemLocation.EQUIPPED:
		drag_locked = true

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

	var half := sprite.size * 0.5
	var lever_x = clamp(_grab_offset_local.x / half.x, -1.0, 1.0)
	var lever_y = clamp(_grab_offset_local.y / half.y, -1.0, 1.0)

	var torque = (_drag_velocity.normalized().y * lever_x) - (_drag_velocity.normalized().x * lever_y)
	var target_rot = clamp(torque * MAX_ROTATION, -MAX_ROTATION, MAX_ROTATION)

	sprite.rotation = lerp(sprite.rotation, target_rot, ROTATION_LERP * delta)
	label.rotation = sprite.rotation

func _reset_rotation(delta: float) -> void:
	sprite.rotation = lerp(sprite.rotation, 0.0, ROTATION_LERP * delta)
	label.rotation = sprite.rotation

func _reset_rotation_immediate() -> void:
	sprite.rotation = 0.0
	label.rotation = 0.0

# -------------------------------------------------
# RETURN
# -------------------------------------------------
func _finish_return() -> void:
	global_position = _target_position
	returning = false
	_reset_rotation_immediate()
	_update_z_index()
	animation_finished.emit(self)
	
func force_snap(pos: Vector2) -> void:
	_target_position = pos
	global_position = pos
	dragging = false
	returning = false
	_reset_rotation_immediate()
	_update_z_index()

# -------------------------------------------------
# Z INDEX
# -------------------------------------------------
func _update_z_index() -> void:
	if dragging:
		z_index = 2000
	elif returning:
		z_index = 1500
	elif item.location == InventoryItemData.ItemLocation.EQUIPPED:
		z_index = 1000
	else:
		z_index = 100

# -------------------------------------------------
# TOOLTIP
# -------------------------------------------------
func _on_mouse_entered() -> void:
	if dragging or returning or tooltip:
		return

	tooltip = preload("res://scene/item_management/item/item_tooltip.tscn").instantiate()
	get_tree().current_scene.add_child(tooltip)
	tooltip.bind(item.equipment)

	await get_tree().process_frame
	tooltip.global_position = global_position + Vector2(-tooltip.size.x - TOOLTIP_PADDING, 0)

func _on_mouse_exited() -> void:
	_close_tooltip()

func _close_tooltip() -> void:
	if tooltip:
		tooltip.queue_free()
		tooltip = null
