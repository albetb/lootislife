# INVENTORY / EQUIPMENT / LOOT – ARCHITECTURAL RULES
#
# 1. Esiste UN SOLO stato logico degli oggetti:
#    Player.data.inventory.
#    Tutti gli item (inventory, equip, loot) stanno nella stessa lista.
#
# 2. La posizione logica di un item è definita solo da:
#    item.location, item.inventory_position, item.equipped_slot.
#    Nessun altro dato rappresenta la posizione.
#
# 3. SOLO l’inventario è autorizzato a modificare lo stato logico degli item.
#    Le modifiche avvengono tramite funzioni dedicate (move_in_grid, move_to_equip).
#    Nessun altro script può settare direttamente quei campi.
#
# 4. ItemMoveController è l’unico orchestratore degli spostamenti.
#    Decide il tipo di drop, avvia animazioni e chiama le funzioni logiche.
#    Non possiede stato persistente.
#
# 5. ItemView è solo rappresentazione visiva.
#    Si muove solo interpolando verso target_position.
#    Non modifica mai lo stato logico dell’item.
#
# 6. Un ItemView è sempre figlio del nodo UI che rappresenta la sua location.
#    Inventory → InventoryGrid.items_layer.
#    Equip → EquipmentSlot.
#
# 7. Un ItemView non viene mai riparentato durante il drag.
#    Il drag è solo movimento visivo temporaneo.
#    Il reparent avviene solo dopo il commit logico.
#
# 8. SOLO ItemMoveController può chiamare reparent() sugli ItemView.
#    Nessun altro script è autorizzato a farlo.
#
# 9. PlayerScreen non decide spostamenti né avvia animazioni.
#    Si limita a sincronizzare la UI con lo stato logico.
#    Non interferisce se view.dragging o view.returning sono true.
#
# 10. Gli oggetti di loot fanno parte dell’inventario globale.
#     Hanno location == LOOT e usano una griglia dedicata.
#     Non esistono liste di oggetti separate.
#
# 11. LootState è solo una vista temporanea del loot.
#     Serve per layout e validazione.
#     Viene creato e distrutto da PlayerScreen.
#
# 12. Le ItemView del loot vengono create all’apertura del loot.
#     Vengono distrutte alla chiusura del loot.
#     Le ItemView di inventory ed equip non vengono mai distrutte.
#
# 13. Ogni spostamento segue sempre questo ordine:
#     animazione → commit logico → reparent → sync UI.
#     Nessuna eccezione.
#
# 14. GridState è sempre derivato.
#     Non possiede dati e non modifica InventoryData.
#     Il layout è sempre ricostruibile dallo stato globale.
#
# 15. PlayerScreen non può mai riparentare o muovere ItemView.
#     Può solo cambiarne visibilità e registrare segnali.
#
# 16. Nessuna animazione deve mai dipendere da PlayerScreen.
#     Tutte le transizioni visive partono da ItemMoveController.
#
# 17. La posizione di un ItemView viene controllata solo tramite target_position.
#     Nessuno script deve settare direttamente global_position o position.
#     Il movimento è sempre gestito internamente da ItemView.
#
# 18. Le ItemView non appartengono a una Grid.
#     Sono gestite globalmente da PlayerScreen.
#     Le Grid sono solo contenitori visivi temporanei.
#
# 19. Ogni ItemView esiste una sola volta.
#     È identificata univocamente dal uid dell’item.
#     Non viene mai duplicata.
#
# 20. Il lookup uid → ItemView è globale.
#     Non può stare in una Grid o in uno Slot.
#     È responsabilità di PlayerScreen.

extends Control
class_name PlayerScreen

@onready var inventory_panel: InventoryPanel = $InventoryPanel
@onready var loot_panel: LootPanel = $LootPanel
@onready var equipment_panel: EquipmentPanel = $LateralStatsBar/VBoxContainer/EquipmentPanel
@onready var toggle_button: Button = $InventoryToggleButton
@onready var inventory_grid: ItemGrid = $InventoryPanel/VBoxContainer/ItemGrid
@onready var sidebar := $LateralStatsBar
@onready var blur_panel := $BlurPanel

@onready var move_controller := ItemMoveController.new()

var inventory_state := InventoryGridState.new()
var loot_state: LootGridState = null

var inventory_open := false
var loot_open := false

const INVENTORY_LERP := 10.0
const INVENTORY_OFFSET := 8

var inventory_target_pos := Vector2.ZERO
var loot_target_pos := Vector2.ZERO
var button_target_pos := Vector2.ZERO


func _ready() -> void:
	add_to_group("player_screen")

	inventory_state.bind_allowed_slots(Player.get_inventory_slots())
	inventory_grid.bind(inventory_state)
	inventory_grid._refresh_views()
	sync_item_views()

	add_child(move_controller)
	move_controller.setup(self)
	move_controller.sync_initial_equipped_views()

	toggle_button.pressed.connect(_on_toggle_inventory)
	inventory_panel.inventory_panel_resized.connect(_update_panels_position)
	loot_panel.loot_panel_resized.connect(_update_panels_position)
	loot_panel.loot_panel_closed.connect(_on_loot_panel_closed)

	Events.update_ui.connect(sync_item_views)
	Events.treasure_loot_requested.connect(_open_loot_panel)

	inventory_panel.visible = true
	_update_panels_position()

	inventory_panel.global_position = inventory_target_pos
	loot_panel.global_position = loot_target_pos
	toggle_button.global_position = button_target_pos


func _process(delta: float) -> void:
	inventory_panel.global_position = inventory_panel.global_position.lerp(
		inventory_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)

	loot_panel.global_position = loot_panel.global_position.lerp(
		loot_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)

	toggle_button.global_position = toggle_button.global_position.lerp(
		button_target_pos,
		1.0 - exp(-INVENTORY_LERP * delta)
	)


# -------------------------------------------------
# PANEL POSITIONING
# -------------------------------------------------
func _on_toggle_inventory() -> void:
	inventory_open = not inventory_open
	_update_button()
	_update_panels_position()


func _update_button() -> void:
	toggle_button.text = ">" if inventory_open else "<"


func _update_panels_position() -> void:
	var sidebar_rect = sidebar.get_global_rect()
	var bottom_y = sidebar_rect.position.y + sidebar_rect.size.y

	if inventory_open:
		inventory_target_pos = Vector2(
			sidebar_rect.position.x - inventory_panel.size.x - INVENTORY_OFFSET,
			bottom_y - inventory_panel.size.y - INVENTORY_OFFSET
		)
		button_target_pos = Vector2(
			inventory_target_pos.x - toggle_button.size.x - INVENTORY_OFFSET,
			bottom_y - toggle_button.size.y - INVENTORY_OFFSET
		)
	else:
		inventory_target_pos = Vector2(
			sidebar_rect.position.x + INVENTORY_OFFSET,
			bottom_y - inventory_panel.size.y - INVENTORY_OFFSET
		)
		button_target_pos = Vector2(
			sidebar_rect.position.x - toggle_button.size.x - INVENTORY_OFFSET,
			bottom_y - toggle_button.size.y - INVENTORY_OFFSET
		)

	if loot_open:
		loot_target_pos = Vector2(
			inventory_target_pos.x - loot_panel.size.x - INVENTORY_OFFSET,
			bottom_y - loot_panel.size.y - INVENTORY_OFFSET
		)
	else:
		loot_target_pos = Vector2(
			sidebar_rect.position.x + INVENTORY_OFFSET,
			bottom_y - loot_panel.size.y - INVENTORY_OFFSET
		)


# -------------------------------------------------
# UI SYNC
# -------------------------------------------------
func sync_item_views() -> void:
	_sync_state(inventory_state)
	if loot_state != null:
		_sync_state(loot_state)


func _sync_state(state: GridState) -> void:
	for item in state.get_items():
		var view: ItemView = inventory_grid.item_views.get(item.uid)
		if view == null:
			continue

		_register_item_view(view)

		if view.dragging or view.returning:
			continue

		match item.location:
			InventoryItemData.ItemLocation.INVENTORY:
				view.visible = true

			InventoryItemData.ItemLocation.LOOT:
				view.visible = loot_open

			InventoryItemData.ItemLocation.EQUIPPED:
				view.visible = true


# -------------------------------------------------
# DROP ENTRY
# -------------------------------------------------
func _register_item_view(view: ItemView) -> void:
	if not view.drop_requested.is_connected(_on_item_drop_requested):
		view.drop_requested.connect(_on_item_drop_requested)


func _on_item_drop_requested(view: ItemView, _global_pos: Vector2) -> void:
	var target := _resolve_drop_target(view)

	move_controller.request_drop(
		view.item,
		view,
		target.type,
		target.grid,
		target.slot,
		target.cell
	)


# -------------------------------------------------
# DROP TARGET RESOLUTION
# -------------------------------------------------
enum DropTargetType { NONE, EQUIPMENT, GRID }

class DropTarget:
	var type := DropTargetType.NONE
	var grid: ItemGrid
	var slot: EquipmentSlot
	var cell := ItemGrid.INVALID_CELL


func _resolve_drop_target(view: ItemView) -> DropTarget:
	var t := DropTarget.new()

	var slot := equipment_panel.get_slot_under_mouse()
	if slot:
		t.type = DropTargetType.EQUIPMENT
		t.slot = slot
		return t

	if loot_open:
		var loot_grid := loot_panel.get_grid()
		var cell := loot_grid.get_best_drop_cell(view)
		if cell != ItemGrid.INVALID_CELL:
			t.type = DropTargetType.GRID
			t.grid = loot_grid
			t.cell = cell
			return t

	var inv_cell := inventory_grid.get_best_drop_cell(view)
	if inv_cell != ItemGrid.INVALID_CELL:
		t.type = DropTargetType.GRID
		t.grid = inventory_grid
		t.cell = inv_cell

	return t


# -------------------------------------------------
# API PER MOVE CONTROLLER
# -------------------------------------------------
func can_equip_item(item: InventoryItemData, slot: EquipmentSlot) -> bool:
	return equipment_panel.can_equip(item, slot)

func find_first_free_inventory_cell(item: InventoryItemData) -> Vector2i:
	return inventory_state.find_first_free_cell(item)

func get_item_view(uid: String) -> ItemView:
	return inventory_grid.item_views.get(uid)

# -------------------------------------------------
# LOOT
# -------------------------------------------------
func _open_loot_panel() -> void:
	if loot_open:
		return

	LootGenerator.generate_test_loot()

	loot_state = LootGridState.new()
	loot_state.setup(4, 4)

	loot_panel.open(loot_state)
	loot_open = true

	blur_panel.visible = true
	toggle_button.visible = false

	if not inventory_open:
		inventory_open = true

	_update_button()
	_update_panels_position()


func _on_loot_panel_closed() -> void:
	loot_state = null
	loot_open = false
	blur_panel.visible = false
	toggle_button.visible = true
	_update_panels_position()
