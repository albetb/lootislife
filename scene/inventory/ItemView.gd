extends Control
class_name ItemView

var item: ItemInstance
var inventory: InventoryState
var grid: InventoryGrid
var tooltip: ItemTooltip
var source_equipment_slot: EquipmentSlot = null
var drag_origin_equipment_slot: EquipmentSlot = null

var dragging := false
var returning := false

var drag_offset := Vector2.ZERO
var original_position := Vector2.ZERO
var target_position := Vector2.ZERO
var grab_offset_local := Vector2.ZERO
var last_mouse_pos := Vector2.ZERO
var drag_velocity := Vector2.ZERO

@onready var visual := $Visual
@onready var invalidOverlay := $InvalidOverlay
var equipment_panel: EquipmentPanel

const TOOLTIP_PADDING := 4
const DRAG_LERP := 18.0
const RETURN_LERP := 14.0
const ROTATION_LERP := 12.0
const MAX_ROTATION := deg_to_rad(8.0)   # massimo tilt
const ROTATION_DEADZONE := 6.0           # px minimi prima di ruotare
const MIN_DRAG_SPEED := 40.0

var grab_local_x := 0.0
var grab_global_y := 0.0
var target_rotation := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	pivot_offset = Vector2.ZERO

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	visual.mouse_filter = Control.MOUSE_FILTER_STOP
	visual.mouse_entered.connect(_on_mouse_entered)
	visual.mouse_exited.connect(_on_mouse_exited)
	visual.gui_input.connect(_on_visual_gui_input)

	target_position = global_position

func _process(delta: float) -> void:
	if dragging:
		target_position = get_global_mouse_position() - drag_offset
		global_position = global_position.lerp(target_position, DRAG_LERP * delta)

		_update_drag_rotation(delta)

	elif returning:
		global_position = global_position.lerp(target_position, RETURN_LERP * delta)
		visual.rotation = lerp(visual.rotation, 0.0, ROTATION_LERP * delta)

		if global_position.distance_to(target_position) < 1.0:
			global_position = target_position
			returning = false

func bind(_item: ItemInstance, _inventory: InventoryState, _grid: InventoryGrid,
	_equipment_panel: EquipmentPanel) -> void:
	item = _item
	inventory = _inventory
	grid = _grid
	equipment_panel = _equipment_panel

	size = Vector2(
		60 * item.size.x + 4 * (item.size.x - 1),
		60 * item.size.y + 4 * (item.size.y - 1)
	)

	visual.size = size
	invalidOverlay.size = size
	invalidOverlay.visible = inventory and inventory.item_is_out_of_bounds(item)

	target_position = global_position

# -------------------------------------------------
# TOOLTIP
# -------------------------------------------------

func _on_mouse_entered() -> void:
	if dragging or returning:
		return
	if tooltip:
		return

	tooltip = preload("res://scene/inventory/item_tooltip.tscn").instantiate()
	get_tree().current_scene.add_child(tooltip)
	tooltip.bind(item)

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

# -------------------------------------------------
# DRAG & DROP
# -------------------------------------------------

func _on_visual_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_end_drag()
			
func _start_drag() -> void:
	dragging = true
	returning = false
	z_index = 2000
	drag_origin_equipment_slot = source_equipment_slot
	
	if source_equipment_slot:
		var slot := source_equipment_slot
		slot.clear_item(item)
		slot.request_unequip.emit(item)
		source_equipment_slot = null
	
	var equipment_slot = equipment_panel.get_slot_under_mouse(drag_origin_equipment_slot)
	if equipment_slot and equipment_slot.current_item == item:
		equipment_slot.clear_item(item)
		equipment_slot.request_unequip.emit(item)

	original_position = global_position
	target_position = global_position

	var mouse_pos := get_global_mouse_position()
	last_mouse_pos = mouse_pos

	# offset per seguire il mouse
	drag_offset = mouse_pos - global_position

	# mouse in coordinate LOCALI dell'ItemView
	var local_mouse := mouse_pos - global_position
	grab_offset_local = local_mouse - size * 0.5

	target_rotation = 0.0

	_close_tooltip()

func _end_drag() -> void:
	if not dragging:
		return

	dragging = false
	z_index = 100

	visual.rotation = 0.0
	invalidOverlay.rotation = 0.0

	var target_cell = grid.get_best_drop_cell(self)
	if target_cell != InventoryGrid.INVALID_CELL:

		# se l’item veniva dall’equip, NON è ancora nella grid
		if drag_origin_equipment_slot:
			reparent(grid)

			if inventory.add_item_from_equipment(item, target_cell):
				# SNAP FORZATO ALLA CELLA
				position = Vector2(target_cell) * grid.SLOT_SIZE
				z_index = 10

				source_equipment_slot = null
				drag_origin_equipment_slot = null

				grid.bind(inventory, equipment_panel)
				return
		else:
			if grid.try_move_item(item, target_cell):
				drag_origin_equipment_slot = null
				return

	# -------------------------------------------------
	# 2️⃣ EQUIP (SOLO SE NON ERA INVENTARIO)
	# -------------------------------------------------
	var equipment_slot := equipment_panel.get_slot_under_mouse(drag_origin_equipment_slot)

	if equipment_slot and equipment_slot.can_drop(self):
		if equipment_slot.drop_item(self):
			inventory.remove_item(item)
			equipment_slot.attach_item_view(self)
			drag_origin_equipment_slot = null
			return

	# -------------------------------------------------
	# 3️⃣ RITORNO ALLO SLOT DI ORIGINE
	# -------------------------------------------------
	if drag_origin_equipment_slot:
		drag_origin_equipment_slot.attach_item_view(self)
		z_index = 0
		drag_origin_equipment_slot = null
		return

	# -------------------------------------------------
	# 4️⃣ RITORNO MAGNETICO
	# -------------------------------------------------
	returning = true
	target_position = original_position

func _update_drag_rotation(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	drag_velocity = (mouse_pos - last_mouse_pos) / max(delta, 0.0001)
	last_mouse_pos = mouse_pos

	var speed := drag_velocity.length()
	if speed < MIN_DRAG_SPEED:
		visual.rotation = lerp(visual.rotation, 0.0, ROTATION_LERP * delta)
		invalidOverlay.rotation = lerp(invalidOverlay.rotation, 0.0, ROTATION_LERP * delta)
		return

	# -----------------------------
	# LEVA (quanto sei lontano dal centro)
	# -----------------------------
	var half_size = visual.size * 0.5

	var lever_x = clamp(grab_offset_local.x / half_size.x, -1.0, 1.0)
	var lever_y = clamp(grab_offset_local.y / half_size.y, -1.0, 1.0)

	# se afferrato vicino al centro → niente rotazione
	var lever_strength = max(abs(lever_x), abs(lever_y))
	if lever_strength < 0.15:
		visual.rotation = lerp(visual.rotation, 0.0, ROTATION_LERP * delta)
		invalidOverlay.rotation = lerp(invalidOverlay.rotation, 0.0, ROTATION_LERP * delta)
		return

	# -----------------------------
	# DIREZIONE (perpendicolare al movimento)
	# -----------------------------
	var movement := drag_velocity.normalized()

	# cross product 2D → scalare
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
	invalidOverlay.rotation = lerp(
		invalidOverlay.rotation,
		target_rotation,
		ROTATION_LERP * delta
	)
