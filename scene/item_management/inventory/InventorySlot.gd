extends Control
class_name InventorySlot

@onready var background := $Background
@onready var disabled_overlay := $DisabledOverlay
@onready var ghost_overlay := $GhostOverlay

const SLOT_SIZE := Vector2(64, 64)

func _ready() -> void:
	# dimensione FISSA dello slot
	size = SLOT_SIZE
	custom_minimum_size = SLOT_SIZE

	# IMPORTANTISSIMO: niente stretch
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 0
	offset_top = 0

	# inizializza overlay
	disabled_overlay.visible = false
	ghost_overlay.visible = false

func setup(x: int, y: int) -> void:
	# niente layout qui
	pass

func set_disabled(value: bool) -> void:
	disabled_overlay.visible = value

func set_out_of_bounds(value: bool) -> void:
	ghost_overlay.visible = value

func set_occupied(value: bool) -> void:
	pass
