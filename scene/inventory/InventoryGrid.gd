extends Control
class_name InventoryGrid

signal grid_resized

@export var slot_scene: PackedScene = preload("res://scene/inventory/inventory_slot.tscn")
@export var item_view_scene: PackedScene = preload("res://scene/inventory/item_view.tscn")
const SLOT_SIZE := Vector2(64, 64)

var equipment_panel: EquipmentPanel
var inventory: InventoryState
var slots: Dictionary = {}          # Vector2i -> InventorySlot
var item_views: Array[ItemView] = []
const INVALID_CELL := Vector2i(-1, -1)

# -------------------------------------------------
# BIND
# -------------------------------------------------

func bind(state: InventoryState, panel: EquipmentPanel) -> void:
	inventory = state
	equipment_panel = panel
	_build_grid()
	_refresh()

# -------------------------------------------------
# GRID BUILD
# -------------------------------------------------

func _build_grid() -> void:
	if inventory == null:
		return

	for child in get_children():
		child.queue_free()

	slots.clear()

	var visible_slots := inventory.get_required_visible_slots()
	var cols := inventory.WIDTH

	for index in range(visible_slots):
		var x := index % cols
		var y := index / cols

		var slot: InventorySlot = slot_scene.instantiate()
		add_child(slot)

		slot.position = Vector2(x, y) * SLOT_SIZE
		slot.setup(x, y)

		var pos := Vector2i(x, y)
		slots[pos] = slot

		# ghost SOLO se oltre allowed_slots
		slot.set_out_of_bounds(index >= inventory.allowed_slots)

	var rows := int(ceil(float(visible_slots) / float(cols)))
	custom_minimum_size = Vector2(
		cols * SLOT_SIZE.x,
		rows * SLOT_SIZE.y
	)
	
	emit_signal("grid_resized")
	
func get_visible_rows() -> int:
	if inventory == null:
		return 0

	var visible_slots := inventory.get_required_visible_slots()
	return int(ceil(float(visible_slots) / float(inventory.WIDTH)))
	
func _refresh() -> void:
	if inventory == null:
		return

	# distruggi view precedenti
	for view in item_views:
		view.queue_free()
	item_views.clear()

	# reset slot occupazione
	for slot in slots.values():
		slot.set_occupied(false)

	# crea UNA ItemView per OGNI entry
	for item in inventory.item_to_entry.keys():
		var entry: InventoryItemData = inventory.item_to_entry[item]

		var view: ItemView = item_view_scene.instantiate()
		add_child(view)
		view.bind(item, inventory, self, equipment_panel)
		item_views.append(view)

		if entry.equipped_slot == EquipmentData.SlotType.NONE:
			view.position = Vector2(item.position) * SLOT_SIZE
			view.z_index = 10

			for dy in range(item.size.y):
				for dx in range(item.size.x):
					var p = item.position + Vector2i(dx, dy)
					if slots.has(p):
						slots[p].set_occupied(true)

		else:
			view.z_index = 0

func get_cell_from_global_position(global_pos: Vector2) -> Vector2i:
	var local_pos := global_pos - global_position
	# ↑ più affidabile di to_local per UI complesse

	var x := int(floor(local_pos.x / SLOT_SIZE.x))
	var y := int(floor(local_pos.y / SLOT_SIZE.y))

	var cell := Vector2i(x, y)

	if not slots.has(cell):
		return INVALID_CELL

	return cell

func _remove_item_from_grid(item: ItemInstance) -> void:
	for i in range(inventory.grid.size()):
		if inventory.grid[i] == item:
			inventory.grid[i] = null
			
func try_move_item(item: ItemInstance, target_cell: Vector2i) -> bool:
	# 1. Salva posizione originale
	var original_pos := item.position

	# 2. Rimuovi temporaneamente l'item dalla griglia
	_remove_item_from_grid(item)

	# 3. Prova a piazzarlo nella nuova posizione
	var success := inventory.place(item, target_cell.x, target_cell.y)

	if not success:
		# 4a. Rollback se fallisce
		inventory.place(item, original_pos.x, original_pos.y)
		return false

	# 4b. Se riesce, aggiorna UI
	_build_grid()
	_refresh()
	return true
	
func get_best_drop_cell(item_view: ItemView) -> Vector2i:
	# posizione dell’angolo top-left dell’item in locale alla griglia
	var local = item_view.global_position - global_position

	var base_x := int(local.x / SLOT_SIZE.x)
	var base_y := int(local.y / SLOT_SIZE.y)

	if base_x < 0 or base_y < 0:
		return INVALID_CELL

	# offset dentro lo slot corrente
	var offset_x = local.x - base_x * SLOT_SIZE.x
	var offset_y = local.y - base_y * SLOT_SIZE.y

	# se l’angolo cade oltre metà slot, slitta
	if offset_x > SLOT_SIZE.x * 0.5:
		base_x += 1
	if offset_y > SLOT_SIZE.y * 0.5:
		base_y += 1

	var cell := Vector2i(base_x, base_y)

	# verifica che l’item ci stia tutto
	for dy in range(item_view.item.size.y):
		for dx in range(item_view.item.size.x):
			if not slots.has(cell + Vector2i(dx, dy)):
				return INVALID_CELL
				
	for dy in range(item_view.item.size.y):
		for dx in range(item_view.item.size.x):
			var p := cell + Vector2i(dx, dy)
			var p_index := p.y * inventory.WIDTH + p.x
			if p_index >= inventory.allowed_slots:
				return INVALID_CELL
		
	return cell
	
func get_items() -> Array[ItemView]:
	return item_views
