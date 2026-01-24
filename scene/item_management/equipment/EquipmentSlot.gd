extends Control
class_name EquipmentSlot

@export var slot_id: InventoryItemData.EquippedSlot

# Texture per slot alti 1 e 2 celle
@export var texture_single: Texture2D
@export var texture_double: Texture2D

const CELL_SIZE := Vector2(64, 64)
const HIGHLIGHT_COLOR := Color(0.6, 1.0, 0.6, 1.0)
const FADE_TIME := 0.18

@onready var background: TextureRect = $Background

var _default_modulate: Color
var _fade_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_background()

	# parte invisibile ma pronta
	background.modulate.a = 0.0
	background.visible = true

	Events.inventory_opened.connect(_on_inventory_opened)
	Events.inventory_closed.connect(_on_inventory_closed)

# -------------------------------------------------
# LAYOUT
# -------------------------------------------------
func get_vertical_cells() -> int:
	match slot_id:
		InventoryItemData.EquippedSlot.HAND_LEFT, \
		InventoryItemData.EquippedSlot.HAND_RIGHT, \
		InventoryItemData.EquippedSlot.ARMOR:
			return 2
		_:
			return 1


func _setup_background() -> void:
	var cells := get_vertical_cells()

	background.texture = (
		texture_double if cells == 2 else texture_single
	)

	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var slot_size := Vector2(
		CELL_SIZE.x,
		CELL_SIZE.y * cells
	)

	custom_minimum_size = slot_size
	size = slot_size

	background.custom_minimum_size = slot_size
	background.size = slot_size

	_default_modulate = background.modulate

# -------------------------------------------------
# VISUALS
# -------------------------------------------------
func set_highlight(enabled: bool) -> void:
	var base_color := (
		HIGHLIGHT_COLOR if enabled else _default_modulate
	)

	# preserva l'alpha corrente (fade)
	base_color.a = background.modulate.a
	background.modulate = base_color


func _on_inventory_opened() -> void:
	_fade_to(1.0)


func _on_inventory_closed() -> void:
	set_highlight(false)
	_fade_to(0.0)


func _fade_to(target_alpha: float) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_QUAD)
	_fade_tween.set_ease(Tween.EASE_OUT)

	_fade_tween.tween_property(
		background,
		"modulate:a",
		target_alpha,
		FADE_TIME
	)

# -------------------------------------------------
# SNAP
# -------------------------------------------------
func get_snap_global_position(view: ItemView) -> Vector2:
	var rect := get_global_rect()
	return rect.position + (rect.size - view.size) * 0.5
