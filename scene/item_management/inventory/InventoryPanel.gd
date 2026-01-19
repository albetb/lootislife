extends Panel
class_name InventoryPanel

signal inventory_panel_resized

@export var slot_size := 64
@export var padding := 16
@export var columns := 4

@onready var grid := $VBoxContainer/InventoryGrid
@onready var title_bar := $VBoxContainer/HBoxContainer/InventoryLabel
@onready var coin_label := $VBoxContainer/HBoxContainer/CoinLabel

func _ready() -> void:
	grid.grid_resized.connect(_on_grid_resized)
	print_tree_pretty()

func configure_from_grid() -> void:
	await get_tree().process_frame

	var rows = grid.get_visible_rows()
	var title_height = title_bar.get_combined_minimum_size().y
	var grid_height = rows * slot_size

	var width_px := columns * slot_size + padding * 2
	var height_px = title_height + grid_height + padding * 2

	custom_minimum_size = Vector2(width_px, height_px)
	size = custom_minimum_size
	coin_label.text = str(Player.data.coins) + " 🪙"

	var vbox := $VBoxContainer
	vbox.add_theme_constant_override("margin_left", padding)
	vbox.add_theme_constant_override("margin_right", padding)
	vbox.add_theme_constant_override("margin_top", padding)
	vbox.add_theme_constant_override("margin_bottom", padding)
	
	emit_signal("inventory_panel_resized")
	
func _on_grid_resized() -> void:
	configure_from_grid()

# -------------------------------------------------
# ITEM CONTAINER INTERFACE
# -------------------------------------------------

func get_grid() -> InventoryGrid:
	return grid

func get_state() -> GridState:
	return grid.grid_state

func allows_equip() -> bool:
	return true

func allows_drop_to_inventory() -> bool:
	return true
