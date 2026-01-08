extends Control
class_name PlayerScreen

@onready var inventory_panel: InventoryPanel = $InventoryPanel
@onready var equipment_panel: EquipmentPanel = $LateralStatsBar/VBoxContainer/EquipmentPanel
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
	inventory_state.bind_data(Player.data.inventory)
	inventory_state.update_allowed_slots(Player.get_inventory_slots())
	equipment_panel.inventory_state = inventory_state

	inventory_grid.bind(inventory_state, equipment_panel)
	equipment_panel.refresh_from_build(Player.data.build, inventory_state, inventory_grid)

	inventory_panel.visible = true
	_position_inventory(true)
	inventory_panel.global_position = inventory_target_pos
	toggle_button.global_position = button_target_pos

	_update_button()
	toggle_button.pressed.connect(_on_toggle_inventory)
	Events.inventory_changed.connect(refresh_inventory)
	#print_tree_pretty()

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
	if inventory_open:
		_set_inventory_items_z(0)

	inventory_open = not inventory_open
	_position_inventory(not inventory_open)
	_update_button()

	if inventory_open:
		_set_inventory_items_z(50)

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
	inventory_state.update_allowed_slots(Player.get_inventory_slots())
	inventory_grid.bind(inventory_state, equipment_panel)

	equipment_panel.refresh_from_build(Player.data.build, inventory_state, inventory_grid)
 
func can_drop_on_equipment(item: ItemInstance) -> bool:
	return Player.data.build.can_equip(item.equipment)
	
func _set_inventory_items_z(z: int) -> void:
	for item in inventory_grid.get_items():
		if item.source_equipment_slot != null:
			item.z_index = 500
		else:
			item.z_index = z
