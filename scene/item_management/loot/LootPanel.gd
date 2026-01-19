extends Panel
class_name LootPanel

signal loot_panel_closed
signal loot_panel_resized

@export var slot_size := 64
@export var padding := 16
@export var columns := 4

@onready var grid: InventoryGrid = $VBoxContainer/InventoryGrid
@onready var label: Label = $VBoxContainer/HBoxContainer/LootLabel
@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton

var loot_state: LootState

func _ready() -> void:
	close_button.pressed.connect(close)
	grid.grid_resized.connect(_on_grid_resized)
	#visible = false
	
func bind(state: LootState) -> void:
	loot_state = state
	grid.bind(loot_state)

func open(state: LootState) -> void:
	loot_state = state
	grid.bind(loot_state)

func is_open() -> bool:
	return loot_state != null

func close() -> void:
	_destroy_remaining_loot()
	grid.clear_all_views()
	loot_state = null
	emit_signal("loot_panel_closed")

func _destroy_remaining_loot() -> void:
	if loot_state == null:
		return

	loot_state.items.clear()
	loot_state.layout.clear()

func _on_grid_resized() -> void:
	_configure_from_grid()

func _configure_from_grid() -> void:
	await get_tree().process_frame

	var rows := grid.get_visible_rows()
	var label_height := label.get_combined_minimum_size().y
	var grid_height := rows * slot_size

	var width_px := columns * slot_size + padding * 2
	var height_px := label_height + grid_height + padding * 2

	custom_minimum_size = Vector2(width_px, height_px)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := $VBoxContainer
	vbox.add_theme_constant_override("margin_left", padding)
	vbox.add_theme_constant_override("margin_right", padding)
	vbox.add_theme_constant_override("margin_top", padding)
	vbox.add_theme_constant_override("margin_bottom", padding)
	
	emit_signal("loot_panel_resized")

# -------------------------------------------------
# ITEM CONTAINER INTERFACE
# -------------------------------------------------

func get_grid() -> InventoryGrid:
	return grid

func get_state() -> GridState:
	return loot_state

func allows_equip() -> bool:
	return true

func allows_drop_to_inventory() -> bool:
	return true
