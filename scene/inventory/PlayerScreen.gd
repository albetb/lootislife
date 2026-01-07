extends Control
class_name PlayerScreen

@onready var inventory_panel: InventoryPanel = $InventoryPanel
@onready var toggle_button: Button = $InventoryToggleButton
@onready var inventory_grid := $InventoryPanel/VBoxContainer/InventoryGrid
@onready var sidebar := $LateralStatsBar

var inventory_state := InventoryState.new()
var inventory_open := false

const INVENTORY_LERP := 10.0

var inventory_target_pos := Vector2.ZERO
var button_target_pos := Vector2.ZERO

const INVENTORY_OFFSET := 8
func _ready() -> void:
	inventory_state.setup()
	inventory_state.update_allowed_slots_from_player()

	var test_item := ItemInstance.new()
	test_item.size = Vector2i(2, 1)
	var success := inventory_state.place(test_item, 2, 4)

	# ORA la griglia vede l’item
	inventory_grid.bind(inventory_state)

	inventory_panel.visible = true
	_position_inventory(true)
	inventory_panel.global_position = inventory_target_pos
	toggle_button.global_position = button_target_pos

	_update_button()
	toggle_button.pressed.connect(_on_toggle_inventory)
	Events.inventory_changed.connect(refresh_inventory)
	
func _process(delta: float) -> void:
	inventory_panel.global_position = inventory_panel.global_position.lerp(
		inventory_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)

	toggle_button.global_position = toggle_button.global_position.lerp(
		button_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)

func _on_toggle_inventory() -> void:
	inventory_open = not inventory_open
	_position_inventory(not inventory_open)
	_update_button()

func _update_button() -> void:
	toggle_button.text = "<"
	if inventory_open:
		toggle_button.text = ">"

func _position_inventory(closed: bool) -> void:
	var sidebar_rect = sidebar.get_global_rect()

	if closed:
		# inventario FUORI a destra
		inventory_target_pos = Vector2(
			sidebar_rect.position.x + INVENTORY_OFFSET,
			sidebar_rect.position.y + INVENTORY_OFFSET
		)

		button_target_pos = Vector2(
			sidebar_rect.position.x - toggle_button.size.x - INVENTORY_OFFSET,
			sidebar_rect.position.y + INVENTORY_OFFSET
		)
	else:
		# inventario APERTO a sinistra della sidebar
		inventory_target_pos = Vector2(
			sidebar_rect.position.x - inventory_panel.size.x - INVENTORY_OFFSET,
			sidebar_rect.position.y + INVENTORY_OFFSET
		)

		button_target_pos = Vector2(
			sidebar_rect.position.x
			- inventory_panel.size.x
			- toggle_button.size.x
			- 2 * INVENTORY_OFFSET,
			sidebar_rect.position.y + INVENTORY_OFFSET
		)

func refresh_inventory() -> void:
	inventory_state.update_allowed_slots_from_player()
	inventory_grid.bind(inventory_state)
