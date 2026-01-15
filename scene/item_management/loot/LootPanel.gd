extends Panel
class_name LootPanel

@export var slot_size := 64
@export var padding := 16
@export var columns := 4

@onready var grid: InventoryGrid = $VBoxContainer/InventoryGrid
@onready var label: Label = $VBoxContainer/MarginContainer/LootLabel
@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton

var loot_state: LootState

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)

func bind(state: LootState, equipment_panel: EquipmentPanel) -> void:
	loot_state = state
	grid.bind(loot_state, equipment_panel)
	_configure()

func _on_close_pressed() -> void:
	_destroy_remaining_loot()
	queue_free()

func _destroy_remaining_loot() -> void:
	for item in loot_state.items:
		if item.location == InventoryItemData.ItemLocation.LOOT:
			item.queue_free()

func _configure() -> void:
	var width_px := columns * slot_size + padding * 2
	var height_px := 4 * slot_size + padding * 2
	custom_minimum_size = Vector2(width_px, height_px)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
